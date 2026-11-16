#! /usr/bin/env node
import fs from 'fs/promises'
import { chooseNativeName } from './choose_native_name.js'

const sparqlEndpoint = 'https://query.wikidata.org/bigdata/namespace/wdq/sparql'
const wikidataApiEndpoint = 'https://www.wikidata.org/w/api.php'
const userAgent = 'maps.black naturalearthtiles downloader v1'

async function querySparql (query, description) {
  const response = await fetch(sparqlEndpoint, {
    method: 'POST',
    headers: {
      accept: 'application/sparql-results+json',
      'content-type': 'application/sparql-query',
      'user-agent': userAgent
    },
    body: query
  })
  if (!response.ok) throw new Error(`Error from wikidata service in ${description}`)
  return response.json()
}

async function fetchEntities (ids) {
  const entities = {}

  // The Wikidata API accepts at most 50 ids per request
  for (let i = 0; i < ids.length; i += 50) {
    const url = new URL(wikidataApiEndpoint)
    url.search = new URLSearchParams({
      action: 'wbgetentities',
      ids: ids.slice(i, i + 50).join('|'),
      props: 'claims',
      format: 'json',
      formatversion: '2'
    }).toString()

    const response = await fetch(url, {
      headers: { 'user-agent': userAgent }
    })
    if (!response.ok) throw new Error(`Error from wikidata API in entity fetch (${response.status})`)
    Object.assign(entities, (await response.json()).entities)
  }

  return entities
}

let ids = []

// TODO: Add qrank as a sorting option for styles
for await (const dirent of await fs.opendir('geojson-ne/')) {
  const geojson = JSON.parse(await fs.readFile(dirent.parentPath +'/'+ dirent.name))
  ids.push(...geojson.features.reduce((p,c) => {
    if (c.properties.wikidataid) p.push(c.properties.wikidataid)
    if (c.properties.WIKIDATAID) p.push(c.properties.WIKIDATAID)
    return p
  }, []))
}
for await (const dirent of await fs.opendir('geojson-ne6/')) {
  const geojson = JSON.parse(await fs.readFile(dirent.parentPath +'/'+ dirent.name))
  ids.push(...geojson.features.reduce((p,c) => {
    if (c.properties.wikidataid) p.push(c.properties.wikidataid)
    if (c.properties.WIKIDATAID) p.push(c.properties.WIKIDATAID)
    return p
  }, []))
}

ids = [...new Set(ids)]

const wikidataIds = ids.map(id => 'wd:' + id).join(' ')

const result = await querySparql(
  `SELECT ?id ?label where { VALUES ?id { ${wikidataIds} } ?id (owl:sameAs* / rdfs:label) ?label }`,
  'translations'
)

// P1705 is the native label; P1559 is the native name. Some features only
// have P1559, so fetch both and choose between them below.
const nativeNames = await querySparql(
  `SELECT ?id ?property ?nativeLabel WHERE {
    VALUES ?id { ${wikidataIds} }
    { ?id wdt:P1559 ?nativeLabel . BIND("P1559" AS ?property) }
    UNION
    { ?id wdt:P1705 ?nativeLabel . BIND("P1705" AS ?property) }
  }`,
  'nativeNames'
)

const languages = []

let translations = result.results.bindings.reduce((p,c) => {
  const id = c.id.value.replace('http://www.wikidata.org/entity/', '')
  const lang = c.label['xml:lang']
  const value = c.label.value
  if (!p[id]) p[id] = {}
  p[id]['name:' + lang] = value
  languages.push('name:' + lang)
  return p
}, {})

const nativeCandidates = nativeNames.results.bindings.reduce((p,c) => {
  const id = c.id.value.replace('http://www.wikidata.org/entity/', '')
  if (!p[id]) p[id] = []
  p[id].push({
    property: c.property.value,
    lang: c.nativeLabel['xml:lang'],
    value: c.nativeLabel.value
  })
  return p
}, {})

// A feature with candidates in several languages needs an official-language
// preference. Single-language features can use their candidate directly.
const ambiguousIds = Object.entries(nativeCandidates)
  .filter(([, candidates]) => new Set(candidates.map(candidate => candidate.lang)).size > 1)
  .map(([id]) => id)

const officialLanguageIds = []
const officialLanguages = {}
if (ambiguousIds.length) {
  const entities = await fetchEntities(ambiguousIds)

  for (const [id, entity] of Object.entries(entities)) {
    const claims = entity.claims?.P37 || []
    officialLanguages[id] = claims
      .filter(claim => claim.mainsnak?.snaktype === 'value')
      .map(claim => claim.mainsnak.datavalue.value.id)

    officialLanguageIds.push(...officialLanguages[id])
  }
}

const languageCodes = {}
if (officialLanguageIds.length) {
  const uniqueLanguageIds = [...new Set(officialLanguageIds)]
  const codes = await querySparql(
    `SELECT ?id ?code WHERE {
      VALUES ?id { ${uniqueLanguageIds.map(id => 'wd:' + id).join(' ')} }
      ?id wdt:P424 ?code
    }`,
    'official language codes'
  )

  for (const row of codes.results.bindings) {
    const id = row.id.value.replace('http://www.wikidata.org/entity/', '')
    languageCodes[id] ||= row.code.value
  }
}

for (const [id, candidates] of Object.entries(nativeCandidates)) {
  const nativeName = chooseNativeName({
    labels: translations[id],
    candidates,
    officialLanguageIds: officialLanguages[id] || [],
    languageCodes
  })

  if (nativeName) {
    translations[id] ||= {}
    translations[id].name = nativeName.value
    translations[id].name_lang = nativeName.lang
  }
}

await fs.writeFile('wikidata.json', JSON.stringify(translations, null, 4))
await fs.writeFile('wikidata_languages.json', JSON.stringify([...new Set(languages)], null, 4))
