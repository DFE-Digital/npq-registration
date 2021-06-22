require.context('govuk-frontend/govuk/assets');

import '../styles/application.scss';
import Rails from 'rails-ujs';
import { initAll } from 'govuk-frontend';
import accessibleAutocomplete from 'accessible-autocomplete';
import schoolPicker from "./school-picker";

Rails.start();
initAll();

if (document.querySelector('#school-picker')) {
  schoolPicker.enhanceSelectElement({
    selectElement: document.querySelector('#school-picker'),
    placeholder: "Start typing to search schools",
  })
}
