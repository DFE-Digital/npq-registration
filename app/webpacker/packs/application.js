require.context('govuk-frontend/govuk/assets');

import '../styles/application.scss';
import Rails from 'rails-ujs';
import { initAll } from 'govuk-frontend';
import accessibleAutocomplete from 'accessible-autocomplete';
import institutionPicker from "./institution-picker";

Rails.start();
initAll();

require('es6-promise').polyfill()
require('isomorphic-fetch')

if (document.querySelector('#school-picker')) {
  institutionPicker.enhanceSelectElement({
    selectElement: document.querySelector('#school-picker'),
    placeholder: "Start typing to search schools",
  })
}
