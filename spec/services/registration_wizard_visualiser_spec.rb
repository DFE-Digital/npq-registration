require "rails_helper"

RSpec.describe RegistrationWizardVisualiser do
  let(:dot_file) { Rails.root.join("tmp/visualisations_test/registration_wizard_visualisation.dot") }
  let(:png_file) { Rails.root.join("tmp/visualisations_test/registration_wizard_visualisation.png") }

  before do
    FileUtils.rm_rf dot_file
    allow_any_instance_of(Object).to receive(:system).and_return(true)
  end

  describe ".call" do
    subject { described_class.call }

    it "generates an dot graph of the wizard" do
      expect { subject }.to change(dot_file, :exist?).from(false).to(true)
    end

    it "generates a PNG of the wizard" do
      expect_any_instance_of(Object).to receive(:system).with(
        "dot",
        "-Tpng",
        dot_file.to_s,
        "-o",
        png_file.to_s,
      )
      subject
    end
  end
end
