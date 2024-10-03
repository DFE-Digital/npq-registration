// Entry point for the build script in your package.json
require.context('govuk-frontend/dist/govuk/assets');

import './controllers';
import Rails from 'rails-ujs';
import accessibleAutocomplete from 'accessible-autocomplete';

import institutionPicker from "./institution-picker";
import countryPicker from "./country-picker";
import ittProviderPicker from "./itt-provider-picker.js";
import cookieBanner from "./cookie-banner";
import mermaid from 'mermaid';
import svgPanZoom from 'svg-pan-zoom';

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

mermaid.initialize({
  startOnLoad: false,
  theme: "base",
  fontSize: "19px",
  themeVariables: {
    primaryColor: "#1D70B8",
    primaryTextColor: "#FFFFFF",
    primaryBorderColor: "#B1B4B6",
    actorBorder: "#B1B4B6",
    noteBkgColor: "#B1B4B6",
    noteBorderColor: "#B1B4B6",
    textColor: "#000000",
    fontFamily: '"GDS Transport", arial, sans-serif',
  },
});

mermaid.run({
  querySelector: ".mermaid",
  postRenderCallback: (id) => {
    const svg = document.querySelector(`#${id}`)
    const svgHeight = svg.parentElement.offsetHeight
    svg.style.height = svgHeight
    svgPanZoom(svg, { 
      controlIconsEnabled: true,
      customEventsHandler: { init: () => {
        // Position controls in the bottom left.
        const controls = svg.querySelector("#svg-pan-zoom-controls")
        controls.setAttribute("transform", `translate(0, ${svgHeight - 75}) scale(0.75, 0.75)`)
      }, destroy: () => {}},
    })
  }
});
