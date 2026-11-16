#! /usr/bin/env node
import fs from 'fs/promises'

const geojson = JSON.parse(await fs.readFile(process.argv[2]))

const wikidata = JSON.parse(await fs.readFile('wikidata.json'))

geojson.features.forEach(c => {
  const wikidataId = c.properties.wikidataid || c.properties.WIKIDATAID
  if (wikidataId && wikidata[wikidataId]) c.properties = {
    ...c.properties,
    ...wikidata[wikidataId]
  }
})

await fs.writeFile(process.argv[2], JSON.stringify(geojson, null, 4))
