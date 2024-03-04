import openregisterLocationPicker from 'govuk-country-and-territory-autocomplete'

const $allCountryAutoCompleteElements = document.querySelectorAll('[data-module="app-country-autocomplete"]')

$allCountryAutoCompleteElements.forEach((component) => {
  openregisterLocationPicker({
    selectElement: component.querySelector('select'),
    url: '/location-autocomplete-graph.json'
  })
})
