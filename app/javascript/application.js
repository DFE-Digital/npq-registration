// Entry point for the build script in your package.json
// GOV.UK Frontend fonts and images are served by Sprockets (see
// config/initializers/assets.rb), so they do not need bundling here.
import Rails from 'rails-ujs';
import accessibleAutocomplete from 'accessible-autocomplete';
import { initCrossServiceHeader } from '@govuk-one-login/service-header/dist/scripts/service-header';

import institutionPicker from "./institution-picker";
// These modules run on import for their side effects and export nothing.
import "./itt-provider-picker.js";
import "./cookie-banner";
import "./print";

Rails.start();
import * as GOVUKFrontend from 'govuk-frontend'


window.GOVUKFrontend = GOVUKFrontend;

window.onload = function init() {
  window.GOVUKFrontend.initAll();
  initCrossServiceHeader();
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
    lookupPath: 'private_childcare_providers',
    order: ['urn', 'name', 'address']
  })
}
