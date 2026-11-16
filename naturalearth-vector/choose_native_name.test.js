import test from 'node:test'
import assert from 'node:assert/strict'
import { chooseNativeName } from './choose_native_name.js'

test('prefers the label in the first official language', () => {
  const name = chooseNativeName({
    labels: {
      'name:es': 'México',
      'name:nah': 'Mexko'
    },
    candidates: [
      { property: 'P1705', lang: 'es', value: 'México' },
      { property: 'P1705', lang: 'nah', value: 'Mexko' }
    ],
    officialLanguageIds: ['Q1321', 'Q13300'],
    languageCodes: { Q1321: 'es', Q13300: 'nah' }
  })

  assert.deepEqual(name, { lang: 'es', value: 'México' })
})

test('uses Wikidata P37 claim order for multi-language countries', () => {
  const name = chooseNativeName({
    labels: {
      'name:nl': 'België',
      'name:fr': 'Belgique',
      'name:de': 'Belgien'
    },
    candidates: [
      { property: 'P1705', lang: 'nl', value: 'Koninkrijk België' },
      { property: 'P1705', lang: 'fr', value: 'Royaume de Belgique' },
      { property: 'P1705', lang: 'de', value: 'Königreich Belgien' }
    ],
    officialLanguageIds: ['Q7411', 'Q150', 'Q188'],
    languageCodes: { Q7411: 'nl', Q150: 'fr', Q188: 'de' }
  })

  assert.deepEqual(name, { lang: 'nl', value: 'België' })
})

test('prefers the shorter native label when one language has several values', () => {
  const name = chooseNativeName({
    labels: { 'name:de': 'Deutschland' },
    candidates: [
      { property: 'P1705', lang: 'de', value: 'Bundesrepublik Deutschland' },
      { property: 'P1705', lang: 'de', value: 'Deutschland' }
    ],
    officialLanguageIds: ['Q188'],
    languageCodes: { Q188: 'de' }
  })

  assert.deepEqual(name, { lang: 'de', value: 'Deutschland' })
})

test('uses the short label instead of a long native label', () => {
  const name = chooseNativeName({
    labels: { 'name:de': 'Österreich' },
    candidates: [
      { property: 'P1705', lang: 'de', value: 'Republik Österreich' }
    ]
  })

  assert.deepEqual(name, { lang: 'de', value: 'Österreich' })
})

test('falls back deterministically when there are no official languages', () => {
  const name = chooseNativeName({
    labels: {},
    candidates: [
      { property: 'P1559', lang: 'fr', value: 'Paris' },
      { property: 'P1705', lang: 'fr', value: 'Paris' }
    ]
  })

  assert.deepEqual(name, { lang: 'fr', value: 'Paris' })
})

test('returns undefined when there is nothing to choose from', () => {
  assert.equal(chooseNativeName({}), undefined)
})
