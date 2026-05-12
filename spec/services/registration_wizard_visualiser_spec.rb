require "rails_helper"

RSpec.describe RegistrationWizardVisualiser do
  before do
    FileUtils.rm_rf Rails.root.join("tmp/visualisations_test")

    allow(Rails.configuration.x).to receive(:dfe_wizard).and_return(dfe_wizard)
  end

  let :dot_file do
    Rails.root.join("tmp/visualisations_test/registration_wizard_visualisation.dot")
  end

  context "with dfe_wizard off" do
    let(:dfe_wizard) { false }

    it "generates an dot graph of the wizard" do
      expect { described_class.call(generate_image: false) }
        .to change(dot_file, :exist?).from(false).to(true)
    end
  end

  context "with dfe_wizard on" do
    let(:dfe_wizard) { true }

    it "generates an dot graph of the wizard" do
      expect { described_class.call(generate_image: false) }
        .to change(dot_file, :exist?).from(false).to(true)
    end
  end
end
