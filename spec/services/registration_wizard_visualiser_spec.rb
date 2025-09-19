require "rails_helper"

RSpec.describe RegistrationWizardVisualiser do
  before { FileUtils.rm_rf Rails.root.join("tmp/visualisations_test") }

  let :dot_file do
    Rails.root.join("tmp/visualisations_test/registration_wizard_visualisation.dot")
  end

  it "generates an dot graph of the wizard" do
    expect { described_class.call(generate_image: false) }
      .to change(dot_file, :exist?).from(false).to(true)
  end
end
