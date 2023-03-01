import { nodeListForEach } from 'govuk-frontend/govuk/common'
import openregisterLocationPicker from 'govuk-country-and-territory-autocomplete'

const $allIttProvidersAutoCompleteElements = document.querySelectorAll('[data-module="app-itt-provider-autocomplete"]')

nodeListForEach($allIttProvidersAutoCompleteElements, (component) => {
  openregisterLocationPicker({
    selectElement: component.querySelector('select'),
    url: ''
  })
})
