import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from '@hotwired/stimulus-webpack-helpers';

const application = Application.start()
const context = require.context('controllers', true, /_controller\.js$/);
application.load(definitionsFromContext(context));

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
