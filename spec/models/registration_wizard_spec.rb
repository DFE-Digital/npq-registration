require "rails_helper"

RSpec.describe RegistrationWizard do
  subject { described_class.new(current_step:, store:, request:, current_user: user) }

  let(:store) { {} }
  let(:session) { {} }
  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:user) { create(:user) }
  let(:current_step) { "share_provider" }

  before { create(:course, :aso) }

  describe "#current_step" do
    it "returns current step" do
      expect(subject.current_step).to be(:share_provider)
    end

    context "when invalid step" do
      subject { described_class.new(current_step: "i_do_not_exist", store:, request:, current_user: user) }

      it "raises an error" do
        expect {
          subject.current_step
        }.to raise_error(RegistrationWizard::InvalidStep)
      end
    end
  end

  describe "#answers" do
    let(:school) { create(:school, establishment_type_code: "1") }

    before do
      mock_previous_funding_api_request(
        course_identifier: "npq-additional-support-offer",
        trn: "1234567",
        response: ecf_funding_lookup_response(previously_funded: false),
      )
    end

    context "when working in Local authority maintained nursery" do
      let(:store) do
        {
          "chosen_provider" => "yes",
          "teacher_catchment" => "england",
          "teacher_catchment_country" => "",
          "works_in_school" => "no",
          "trn_knowledge" => "yes",
          "trn" => "123456",
          "full_name" => "Maia Mack",
          "date_of_birth" => 30.years.ago,
          "national_insurance_number" => "123420",
          "trn_auto_verified" => nil,
          "verified_trn" => nil,
          "works_in_childcare" => "yes",
          "kind_of_nursery" => "local_authority_maintained_nursery",
          "institution_location" => "London",
          "institution_name" => "",
          "institution_identifier" => "School-#{school.urn}",
          "course_identifier" => "npq-additional-support-offer",
          "lead_provider_id" => LeadProvider.all.sample.id,
          "funding" => "self",
          "referred_by_return_to_teaching_adviser" => "no",
        }
      end

      it "does not show Ofsted registration details" do
        expect(subject.answers.map(&:key)).not_to include("Ofsted registration details")
      end
    end

    context "when working in private nursery" do
      let(:private_childcare_provider) { create(:private_childcare_provider) }
      let(:store) do
        {
          "chosen_provider" => "yes",
          "course_identifier" => "npq-additional-support-offer",
          "date_of_birth" => 30.years.ago,
          "full_name" => "Tatyana Christensen",
          "has_ofsted_urn" => has_ofsted_urn,
          "institution_identifier" => institution_identifier,
          "institution_location" => "manchester",
          "institution_name" => "",
          "kind_of_nursery" => "private_nursery",
          "lead_provider_id" => LeadProvider.all.sample.id,
          "national_insurance_number" => "123420",
          "teacher_catchment" => "england",
          "teacher_catchment_country" => "",
          "trn" => "123456",
          "trn_auto_verified" => nil,
          "trn_knowledge" => "yes",
          "verified_trn" => nil,
          "works_in_childcare" => "yes",
          "works_in_school" => "no",
          "referred_by_return_to_teaching_adviser" => "no",
        }
      end

      context "without urn" do
        let(:has_ofsted_urn) { "no" }
        let(:institution_identifier) { "" }

        it "does not show Ofsted registration details" do
          expect(subject.answers.map(&:key)).not_to include("Ofsted registration details")
        end

        it "shows Do you have a URN?" do
          expect(subject.answers.map(&:key)).to include("Ofsted unique reference number (URN)")
        end

        it "does not show Nursery" do
          expect(subject.answers.map(&:key)).not_to include("Nursery")
        end
      end

      context "with urn" do
        let(:has_ofsted_urn) { "yes" }
        let(:institution_identifier) { private_childcare_provider.identifier }

        it "shows Ofsted registration details" do
          expect(subject.answers.map(&:key)).to include("Ofsted unique reference number (URN)")
        end

        it "does not show Do you have a URN?" do
          expect(subject.answers.map(&:key)).not_to include("Do you have a URN?")
        end

        it "does not show Nursery" do
          expect(subject.answers.map(&:key)).not_to include("Nursery")
        end
      end
    end
  end
end
