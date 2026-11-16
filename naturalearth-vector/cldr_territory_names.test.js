import test from 'node:test'
import assert from 'node:assert/strict'
import {
  applyCldrTerritoryNames,
  chooseOfficialLanguage,
  getIso2,
  normalizeLanguage
} from './cldr_territory_names.js'

test('prefers official languages, then the largest population share', () => {
  assert.equal(chooseOfficialLanguage({
    languagePopulation: {
      en: { _populationPercent: '59' },
      nl: { _populationPercent: '55', _officialStatus: 'official' },
      fr: { _populationPercent: '38', _officialStatus: 'official' },
      de: { _populationPercent: '22', _officialStatus: 'official' }
    }
  }), 'nl')
})

test('falls back to de facto official languages', () => {
  assert.equal(chooseOfficialLanguage({
    languagePopulation: {
      es: { _populationPercent: '83', _officialStatus: 'de_facto_official' },
      en: { _populationPercent: '13' }
    }
  }), 'es')
})

test('uses the CLDR name for the local language', () => {
  const geojson = {
    features: [{
      properties: { ISO_A2: 'MX', name: 'Mexko' }
    }]
  }

  applyCldrTerritoryNames(
    geojson,
    { MX: { languagePopulation: { es: { _populationPercent: '83', _officialStatus: 'de_facto_official' } } } },
    {
      es: { MX: 'México' },
      en: { MX: 'Mexico' }
    },
    { en: 'name:en' }
  )

  assert.equal(geojson.features[0].properties.name, 'México')
  assert.equal(geojson.features[0].properties.name_lang, 'es')
  assert.equal(geojson.features[0].properties['name:en'], 'Mexico')
})

test('normalizes CLDR script separators', () => {
  assert.equal(normalizeLanguage('zh_Hant'), 'zh-Hant')
})

test('falls back to ISO_A2_EH when ISO_A2 is missing', () => {
  assert.equal(getIso2({ ISO_A2: '-99', ISO_A2_EH: 'XK' }), 'XK')
})
