/**
 * Pick the language whose CLDR territory name should be used as the local name.
 *
 * CLDR's territoryInfo lists a population percentage and an official status for
 * each language. Prefer official languages, then the language with the largest
 * share of the population.
 *
 * @param {{languagePopulation?: Record<string, {_populationPercent?: string, _officialStatus?: string}>}} territoryInfo
 * @returns {string | undefined}
 */
export function chooseOfficialLanguage (territoryInfo) {
  const languages = Object.entries(territoryInfo?.languagePopulation || {})
  if (!languages.length) return undefined

  const rank = status => ({
    official: 3,
    de_facto_official: 2,
    official_regional: 1
  }[status] || 0)

  const official = languages.filter(([, info]) => rank(info._officialStatus) > 0)
  const candidates = official.length ? official : languages

  return candidates.sort(([langA, infoA], [langB, infoB]) => {
    const rankDiff = rank(infoB._officialStatus) - rank(infoA._officialStatus)
    if (rankDiff) return rankDiff

    const populationDiff =
      parseFloat(infoB._populationPercent || 0) -
      parseFloat(infoA._populationPercent || 0)
    if (populationDiff) return populationDiff

    return langA.localeCompare(langB)
  })[0][0]
}

/**
 * Apply CLDR country names to a Natural Earth GeoJSON FeatureCollection.
 *
 * `territoriesByLanguage` is keyed by CLDR language code and contains the
 * `localeDisplayNames.territories` object from CLDR's territories.json.
 *
 * @param {{features: Array}} geojson
 * @param {Record<string, object>} territoryInfo
 * @param {Record<string, Record<string, string>>} territoriesByLanguage
 * @param {Record<string, string>} languageFields Map of CLDR language code to GeoJSON field.
 * @returns {number} number of features changed
 */
export function applyCldrTerritoryNames (geojson, territoryInfo, territoriesByLanguage, languageFields) {
  let changed = 0

  for (const feature of geojson.features || []) {
    const properties = feature.properties || {}
    const iso2 = getIso2(properties)
    if (!iso2) continue

    const info = territoryInfo[iso2]
    if (!info) continue

    const localLanguage = chooseOfficialLanguage(info)
    if (!localLanguage) continue

    const localName = territoriesByLanguage[normalizeLanguage(localLanguage)]?.[iso2]
    if (localName) {
      properties.name = localName
      properties.name_lang = normalizeLanguage(localLanguage)
    }

    for (const [language, field] of Object.entries(languageFields)) {
      const name = territoriesByLanguage[normalizeLanguage(language)]?.[iso2]
      if (name) properties[field] = name
    }

    changed++
  }

  return changed
}

export function normalizeLanguage (language) {
  return language.replace(/_/g, '-')
}

export function getIso2 (properties) {
  return [properties.ISO_A2, properties.ISO_A2_EH, properties.iso_a2]
    .map(value => String(value || '').toUpperCase())
    .find(value => /^[A-Z]{2}$/.test(value))
}
