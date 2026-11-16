#! /usr/bin/env node
import fs from 'fs/promises'
import path from 'path'
import { fileURLToPath } from 'url'
import {
  applyCldrTerritoryNames,
  chooseOfficialLanguage,
  getIso2,
  normalizeLanguage
} from './cldr_territory_names.js'

const cldrBase = 'https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json'
const scriptDir = path.dirname(fileURLToPath(import.meta.url))
const cacheDir = path.join(scriptDir, '.cldr-cache')
const userAgent = 'maps.black naturalearthtiles downloader v1'

// These are the `maplanguages` used by naturalearth-vector/build.sh.  CLDR
// calls traditional Chinese `zh-Hant`, while the tiles call it `zht`.
const languageFields = {
  ar: 'name:ar',
  bn: 'name:bn',
  de: 'name:de',
  el: 'name:el',
  en: 'name:en',
  es: 'name:es',
  fa: 'name:fa',
  fr: 'name:fr',
  he: 'name:he',
  hi: 'name:hi',
  hu: 'name:hu',
  id: 'name:id',
  it: 'name:it',
  ja: 'name:ja',
  ko: 'name:ko',
  nl: 'name:nl',
  pl: 'name:pl',
  pt: 'name:pt',
  ru: 'name:ru',
  sv: 'name:sv',
  tr: 'name:tr',
  uk: 'name:uk',
  ur: 'name:ur',
  vi: 'name:vi',
  zh: 'name:zh',
  'zh-Hant': 'name:zht'
}

async function readCachedJson (url, cachePath) {
  try {
    return JSON.parse(await fs.readFile(cachePath))
  } catch (error) {
    if (error.code !== 'ENOENT') throw error
  }

  const response = await fetch(url, { headers: { 'user-agent': userAgent } })
  if (!response.ok) {
    const error = new Error(`Error fetching ${url}: ${response.status}`)
    error.status = response.status
    throw error
  }

  const data = await response.json()
  await fs.mkdir(path.dirname(cachePath), { recursive: true })
  await fs.writeFile(cachePath, JSON.stringify(data))
  return data
}

async function readTerritories (language) {
  const normalized = language.replace(/_/g, '-')
  try {
    const data = await readCachedJson(
      `${cldrBase}/cldr-localenames-full/main/${normalized}/territories.json`,
      path.join(cacheDir, normalized, 'territories.json')
    )
    return data.main[normalized].localeDisplayNames.territories
  } catch (error) {
    // Not every CLDR language has a full locale file. Fall back to the
    // languages that do instead of failing the whole build.
    if (error.status === 404) {
      console.warn(`CLDR has no territories.json for ${normalized}, skipping`)
      return {}
    }
    throw error
  }
}

async function readTerritoryInfo () {
  const data = await readCachedJson(
    `${cldrBase}/cldr-core/supplemental/territoryInfo.json`,
    path.join(cacheDir, 'territoryInfo.json')
  )
  return data.supplemental.territoryInfo
}

async function main () {
  const filename = process.argv[2]
  if (!filename) {
    console.error('Usage: add_cldr_territory_names.js <geojson>')
    process.exit(1)
  }

  const geojson = JSON.parse(await fs.readFile(filename))
  const territoryInfo = await readTerritoryInfo()

  const localLanguages = geojson.features
    .map(feature => {
      const iso2 = getIso2(feature.properties || {})
      return iso2 && territoryInfo[iso2] && chooseOfficialLanguage(territoryInfo[iso2])
    })
    .filter(Boolean)

  const languages = [...new Set([
    ...Object.keys(languageFields),
    ...localLanguages
  ])]

  const territoriesByLanguage = {}
  for (const language of languages) {
    territoriesByLanguage[normalizeLanguage(language)] = await readTerritories(language)
  }

  applyCldrTerritoryNames(geojson, territoryInfo, territoriesByLanguage, languageFields)
  await fs.writeFile(filename, JSON.stringify(geojson, null, 4))
}

main().catch(error => {
  console.error(error)
  process.exit(1)
})
