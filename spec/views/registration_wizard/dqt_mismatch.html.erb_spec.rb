require "rails_helper"

RSpec.describe "registration_wizard/dqt_mismatch.html.erb", type: :view do
  let(:request) { {} }
  let(:wizard) do
    RegistrationWizard.new(
      current_step: :dqt_mismatch,
      store:,
      request:,
    )
  end

  context "when NI number is present" do
    let(:store) do
      {
        "date_of_birth" => 30.years.ago,
        "national_insurance_number" => "AB123456C",
      }
    end

    it "playbacks NI number" do
      assign(:wizard, wizard)

      render
      expect(rendered).to have_content("AB123456C")
    end

    it "does not have NI number suggestion text" do
      assign(:wizard, wizard)

      render
      expect(rendered).not_to have_content("entering your National Insurance number")
    end
  end

  context "when NI number is not present" do
    let(:store) do
      {
        "date_of_birth" => 30.years.ago,
      }
    end

    it "displays NI number suggestion text" do
      assign(:wizard, wizard)

      render
      expect(rendered).to have_content("entering your National Insurance number")
    end
  end
end
