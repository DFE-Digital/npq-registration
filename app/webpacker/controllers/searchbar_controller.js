import { Controller } from "@hotwired/stimulus"
import accessibleAutocomplete from 'accessible-autocomplete'

export default class extends Controller {
  static values = {
    label: String
  }

  connect() {
    const countries = [
      'France',
      'Germany',
      'United Kingdom'
    ]

    accessibleAutocomplete({
      element: this.element.querySelector('#searchbar-autocomplete-container'),
      id: 'searchbar-autocomplete',
      source: countries
    })
  }
}
