import { nodeListForEach } from 'govuk-frontend/dist/govuk/common'
import openregisterLocationPicker from 'govuk-country-and-territory-autocomplete'

const $allIttProvidersAutoCompleteElements = document.querySelectorAll('[data-module="app-itt-provider-autocomplete"]')

nodeListForEach($allIttProvidersAutoCompleteElements, (component) => {
  const options = component.querySelectorAll('select option');
  const optionsMap = []
  nodeListForEach(options, (option) => {
    optionsMap.push({ search: option.text.toLowerCase(), text: option.text, value: option.value })

    if (option.dataset.additionalSynonyms) {
      JSON.parse(option.dataset.additionalSynonyms).forEach(alias => {
        optionsMap.push({search: alias.toLowerCase(), text: alias, value: option.value})
      })
    }
  })
  console.log(window.opts = optionsMap)

  openregisterLocationPicker({
    selectElement: component.querySelector('select'),
    url: '',
    source (query, callback) {
      const distinct = {}

      const filtered = optionsMap.filter(option => option.search.includes(query.toLowerCase()))
      filtered.forEach(option => {
        distinct[option.value] = distinct[option.value] || { path: option.text !== option.value && option.text , name: option.value }
      })
      callback(Object.values(distinct))
    }
  })
})
