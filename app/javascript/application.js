// Entry point for the build script in your package.json
require.context('govuk-frontend/dist/govuk/assets');

import './controllers';
import Rails from 'rails-ujs';
import accessibleAutocomplete from 'accessible-autocomplete';

import institutionPicker from "./institution-picker";
import countryPicker from "./country-picker";
import ittProviderPicker from "./itt-provider-picker.js";

Rails.start();
import * as GOVUKFrontend from 'govuk-frontend'


window.GOVUKFrontend = GOVUKFrontend;

window.onload = function init() {
  window.GOVUKFrontend.initAll();
};


require('es6-promise').polyfill()
require('isomorphic-fetch')

if (document.querySelector('#school-picker')) {
  institutionPicker.enhanceSelectElement({
    selectElement: document.querySelector('#school-picker'),
    lookupPath: 'institutions',
  })
}

if (document.querySelector('#nursery-picker')) {
  institutionPicker.enhanceSelectElement({
    selectElement: document.querySelector('#nursery-picker'),
    lookupPath: 'institutions',
  })
}

if (document.querySelector('#private-childcare-provider-picker')) {
  institutionPicker.enhanceSelectElement({
    selectElement: document.querySelector('#private-childcare-provider-picker'),
    lookupPath: 'private_childcare_providers'
  })
}