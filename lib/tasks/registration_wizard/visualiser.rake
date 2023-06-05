# frozen_string_literal: true

namespace :registration_wizard do
  desc "Generates a PNG file in tmp/visualisations that displays the registration wizard flow"
  task visualise: :environment do |_t, _args|
    Services::RegistrationWizardVisualiser.call
  end
end
