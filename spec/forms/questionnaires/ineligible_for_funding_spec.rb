require "rails_helper"

RSpec.describe Questionnaires::IneligibleForFunding, type: :model do
  describe "#ineligible_template" do
    let(:form) { described_class.new }
    let(:tsf_eligible) { false }

    subject { form.ineligible_template }

    before do
      allow(form).to receive(:funding_eligiblity_status_code) { funding_eligiblity_status_code }
      allow(form).to receive(:tsf_elgible?) { tsf_eligible }
    end

    (FundingEligibility.constants - %i[FUNDED_ELIGIBILITY_RESULT FUNDING_STATUS_CODE_DESCRIPTIONS]).each do |constant|
      context "when the funding eligibility is #{constant}" do
        let(:funding_eligiblity_status_code) { FundingEligibility.const_get(constant) }

        it "returns a template name" do
          expect(subject).to be_a(String)
        end

        it "the template name refers to a partial that exists" do
          template_path = subject.split("/")
          template_dir = template_path.first if template_path.size > 1
          expect(File.exist?("app/views/registration_wizard/ineligible_for_funding/#{template_dir}/_#{template_path.last}.html.erb")).to be true
        end
      end
    end

    context "when the funding eligibility is #{FundingEligibility::PREVIOUSLY_FUNDED} and tsf_eligible? is true" do
      let(:funding_eligiblity_status_code) { FundingEligibility::PREVIOUSLY_FUNDED }
      let(:tsf_eligible) { true }

      it "returns a template name" do
        expect(subject).to be_a(String)
      end
    end
  end
end
