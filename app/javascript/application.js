// Entry point for the build script in your package.json
require.context('govuk-frontend/dist/govuk/assets');

import Rails from 'rails-ujs';
import accessibleAutocomplete from 'accessible-autocomplete';

import institutionPicker from "./institution-picker";
import ittProviderPicker from "./itt-provider-picker.js";
import cookieBanner from "./cookie-banner";
import print from "./print";

Rails.start();
import * as GOVUKFrontend from 'govuk-frontend'


window.GOVUKFrontend = GOVUKFrontend;

window.onload = function init() {
  window.GOVUKFrontend.initAll();
};

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
