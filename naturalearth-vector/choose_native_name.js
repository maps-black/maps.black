/**
 * Pick one name to expose as the feature's local/native `name`.
 *
 * The candidates come from Wikidata P1559 (native name) and P1705 (native
 * label). Countries often have several native labels in different official
 * languages (Mexico has both `es` and `nah`, Belgium has `nl`, `fr` and `de`),
 * so simply letting the last SPARQL row win is arbitrary.
 *
 * Preference order:
 *   1. A `rdfs:label` in the first official language of the feature.  Wikidata
 *      stores P37 claims in a meaningful order (e.g. Belgium: nl, fr, de).
 *   2. A P1559/P1705 candidate in one of those official languages.
 *   3. A deterministic fallback among all candidates: P1705 before P1559,
 *      then the shortest value, then lexicographic order.
 *
 * @param {object} labels Object containing `name:<lang>` properties.
 * @param {Array<{property: string, lang: string, value: string}>} candidates
 * @param {string[]} officialLanguageIds Wikidata QIDs of official languages.
 * @param {Record<string, string>} languageCodes Map of language QID to code.
 * @returns {{lang: string, value: string} | undefined}
 */
export function chooseNativeName ({ labels = {}, candidates = [], officialLanguageIds = [], languageCodes = {} }) {
  const byLanguage = new Map()

  for (const candidate of candidates) {
    const current = byLanguage.get(candidate.lang)
    if (!current || isBetterCandidate(candidate, current)) {
      byLanguage.set(candidate.lang, candidate)
    }
  }

  for (const languageId of officialLanguageIds) {
    const lang = languageCodes[languageId]
    if (!lang) continue

    const label = labels['name:' + lang]
    if (label) return { lang, value: label }

    const candidate = byLanguage.get(lang)
    if (candidate) return { lang, value: candidate.value }
  }

  const fallback = [...byLanguage.values()].sort(compareCandidates)[0]
  if (!fallback) return undefined

  return {
    lang: fallback.lang,
    value: labels['name:' + fallback.lang] || fallback.value
  }
}

function isBetterCandidate (candidate, current) {
  // P1705 is the native label; P1559 is the (usually shorter) native name.
  // Prefer P1705 only when the two differ, then prefer the shorter value.
  if (candidate.property !== current.property) {
    return candidate.property === 'P1705'
  }
  if (candidate.value.length !== current.value.length) {
    return candidate.value.length < current.value.length
  }
  return candidate.value.localeCompare(current.value) < 0
}

function compareCandidates (a, b) {
  if (a.property !== b.property) return a.property === 'P1705' ? -1 : 1
  if (a.value.length !== b.value.length) return a.value.length - b.value.length
  return a.lang.localeCompare(b.lang) || a.value.localeCompare(b.value)
}
