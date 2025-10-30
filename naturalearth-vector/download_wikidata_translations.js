#! /usr/bin/env node
import fs from 'fs/promises'

import { Agent } from 'undici';

const dispatcher = new Agent({
  connect: {
    socketPath: process.env.NGINX_SOCKET
  }
})

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

const result = await fetch('http://query.wikidata.org/bigdata/namespace/wdq/sparql', {
  dispatcher,
  method: 'POST',
  headers: {
    accept: 'application/sparql-results+json',
    'content-type': 'application/sparql-query',
    'user-agent': 'maps.black naturalearthtiles downloader v1'
  },
  body: `SELECT ?id ?label where { VALUES ?id { ${ids.map(id => 'wd:' + id).join(' ')} } ?id (owl:sameAs* / rdfs:label) ?label }`
}).then(res => {
  if (!res.ok) throw new Error('Error from wikidata service in translations')
  return res.json()
})

// These should probably be P1705, but we have a few (~10) that have P1559 but not P1705
const nativeNames = await fetch('http://query.wikidata.org/bigdata/namespace/wdq/sparql', {
  dispatcher,
  method: 'POST',
  headers: {
    accept: 'application/sparql-results+json',
    'content-type': 'application/sparql-query',
    'user-agent': 'maps.black naturalearthtiles downloader v1'
  },
  body: `SELECT ?id ?nativeLabel WHERE { VALUES ?id {  ${ids.map(id => 'wd:' + id).join(' ')}  } ?id wdt:P1559 ?nativeLabel }`
}).then(res => {
  if (!res.ok) throw new Error('Error from wikidata service in nativeLabels')
  return res.json()
})

const nativeLabels = await fetch('http://query.wikidata.org/bigdata/namespace/wdq/sparql', {
  dispatcher,
  method: 'POST',
  headers: {
    accept: 'application/sparql-results+json',
    'content-type': 'application/sparql-query',
    'user-agent': 'maps.black naturalearthtiles downloader v1'
  },
  body: `SELECT ?id ?nativeLabel WHERE { VALUES ?id {  ${ids.map(id => 'wd:' + id).join(' ')}  } ?id wdt:P1705 ?nativeLabel }`
}).then(res => {
  if (!res.ok) throw new Error('Error from wikidata service in nativeLabels')
  return res.json()
})

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

// TODO: Include all of these separated by slash? Seems to be like that in http://maplibre.org/maplibre-gl-js/docs/examples/display-and-style-rich-text-labels/
translations = nativeNames.results.bindings.reduce((p,c) => {
  const id = c.id.value.replace('http://www.wikidata.org/entity/', '')
  const lang = c.nativeLabel['xml:lang']
  const value = c.nativeLabel.value
  if (!p[id]) p[id] = {}
  p[id]['name'] = value
  p[id]['name_lang'] = lang
  return p
}, translations)

translations = nativeLabels.results.bindings.reduce((p,c) => {
  const id = c.id.value.replace('http://www.wikidata.org/entity/', '')
  const lang = c.nativeLabel['xml:lang']
  const value = c.nativeLabel.value
  if (!p[id]) p[id] = {}
  p[id]['name'] = value
  p[id]['name_lang'] = lang
  return p
}, translations)

await fs.writeFile('wikidata.json', JSON.stringify(translations, null, 4))
await fs.writeFile('wikidata_languages.json', JSON.stringify([...new Set(languages)], null, 4))
