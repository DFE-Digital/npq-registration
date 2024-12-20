import accessibleAutocomplete from 'accessible-autocomplete'
import debounce from 'lodash.debounce'

function schoolPicker (options) {
  if (!options.element) { throw new Error('element is not defined') }
  if (!options.id) { throw new Error('id is not defined') }

  accessibleAutocomplete({
    element: options.element,
    ...options
  })
}

async function fetchSource(query, location) {
  const res  = await fetch( `/schools.json?location=${encodeURIComponent(location)}&name=${encodeURIComponent(query)}` );
  const data = await res.json();
  return data;
}

schoolPicker.enhanceSelectElement = (configurationOptions) => {
  if (!configurationOptions.selectElement) { throw new Error('selectElement is not defined') }

  configurationOptions.onConfirm = function(object) {
    if (object !== undefined) {
      configurationOptions.selectElement.value = object.urn
    }
  }

  configurationOptions.minLength = 2

  configurationOptions.defaultValue = ""

  configurationOptions.displayMenu = "overlay"

  configurationOptions.templates = {
    inputValue: function(object) {
      if (object === undefined) {
        return ""
      } else {
        return object.name + " - " + object.address
      }
    },
    suggestion: function(object) {
      if (object === undefined) {
        return ""
      } else {
        return object.name + " - " + object.address
      }
    }
  }

  const location = configurationOptions.selectElement.getAttribute("data-institution-location")

  configurationOptions.source = debounce( async ( query, populateResults ) => {
    const res = await fetchSource(query, location);
    populateResults(res);
  }, 300 )

  if (configurationOptions.name === undefined) configurationOptions.name = ''

  if (configurationOptions.id === undefined) {
    if (configurationOptions.selectElement.id === undefined) {
      configurationOptions.id = ''
    } else {
      configurationOptions.id = configurationOptions.selectElement.id
    }
  }

  if (configurationOptions.autoselect === undefined) configurationOptions.autoselect = true

  const element = document.createElement('div')

  configurationOptions.selectElement.parentNode.insertBefore(element, configurationOptions.selectElement)

  schoolPicker({
    ...configurationOptions,
    element: element
  })

  configurationOptions.selectElement.style.display = 'none'
  configurationOptions.selectElement.id = configurationOptions.selectElement.id + '-select'
}

export default schoolPicker
