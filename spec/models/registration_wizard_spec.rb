require "rails_helper"

RSpec.describe RegistrationWizard do
  let(:store) { {} }
  let(:session) { {} }
  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:current_step) { "share_provider" }

  subject { described_class.new(current_step: current_step, store: store, request: request) }

  describe "#current_step" do
    it "returns current step" do
      expect(subject.current_step).to eql(:share_provider)
    end

    context "when invalid step" do
      subject { described_class.new(current_step: "i_do_not_exist", store: store, request: request) }

      it "raises an error" do
        expect {
          subject.current_step
        }.to raise_error(RegistrationWizard::InvalidStep)
      end
    end

    context "when registration is closed" do
      before do
        allow(Services::Feature).to receive(:features_enabled?).and_return(true)
        allow(Services::Feature).to receive(:registration_closed?).and_return(true)
      end

      it "always returns closed" do
        expect(subject.current_step).to eql(:closed)
      end
    end
  end

  describe "#answers" do
    let(:school) { create(:school, establishment_type_code: "1") }

    before do
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/123456?npq_course_identifier=npq-additional-support-offer")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
        )
       .to_return(
         status: 200,
         body: previously_funded_response(false),
         headers: {
           "Content-Type" => "application/vnd.api+json",
         },
       )
    end

    context "when ASO is selected course and is eligible for funding" do
      let(:store) do
        {
          "date_of_birth" => 30.years.ago,
          "works_in_school" => "yes",
          "institution_identifier" => "School-#{school.urn}",
          "teacher_catchment" => "england",
          "course_id" => Course.find_by(name: "Additional Support Offer for new headteachers").id,
          "lead_provider_id" => LeadProvider.all.sample.id,
          "funding_choice" => "school",
          "aso_headteacher" => "yes",
          "aso_new_headteacher" => "yes",
          "aso_funding" => "yes",
          "aso_funding_choice" => "another",
          "trn" => "123456",
        }
      end

      it "does not show How is your NPQ being paid for?" do
        expect(subject.answers.map(&:key)).to_not include("How is your NPQ being paid for?")
      end

      it "does not show ASO funding option" do
        expect(subject.answers.map(&:key)).to_not include("How is the Additional Support Offer being paid for?")
      end
    end

    context "when ASO and not eligible for funding" do
      let(:store) do
        {
          "date_of_birth" => 30.years.ago,
          "works_in_school" => "yes",
          "institution_identifier" => "School-#{school.urn}",
          "course_id" => Course.find_by(name: "Additional Support Offer for new headteachers").id,
          "lead_provider_id" => LeadProvider.all.sample.id,
          "aso_funding" => "yes",
          "aso_funding_choice" => "another",
          "trn" => "123456",
        }
      end

      it "shows ASO funding option" do
        expect(subject.answers.find { |el| el.key == "How is the Additional Support Offer being paid for?" }.value).to eql("The Early Headship Coaching Offer is being paid in another way")
      end
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
          "trn_verified" => false,
          "trn_auto_verified" => nil,
          "verified_trn" => nil,
          "works_in_childcare" => "yes",
          "works_in_nursery" => "yes",
          "kind_of_nursery" => "local_authority_maintained_nursery",
          "institution_location" => "London",
          "institution_name" => "",
          "institution_identifier" => "School-#{school.urn}",
          "course_id" => Course.find_by(name: "Additional Support Offer for new headteachers").id,
          "lead_provider_id" => LeadProvider.all.sample.id,
          "funding" => "self",
        }
      end

      it "does not show Ofsted registration details" do
        expect(subject.answers.map(&:key)).to_not include("Ofsted registration details")
      end
    end

    context "when working in private nursery" do
      let(:private_childcare_provider) { create(:private_childcare_provider) }
      let(:store) do
        {
          "chosen_provider" => "yes",
          "course_id" => Course.find_by(name: "Additional Support Offer for new headteachers").id,
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
          "trn_verified" => false,
          "verified_trn" => nil,
          "works_in_childcare" => "yes",
          "works_in_nursery" => "yes",
          "works_in_school" => "no",
        }
      end

      context "without urn" do
        let(:has_ofsted_urn) { "no" }
        let(:institution_identifier) { "" }

        it "does not show Ofsted registration details" do
          expect(subject.answers.map(&:key)).to_not include("Ofsted registration details")
        end

        it "shows Do you have a URN?" do
          expect(subject.answers.map(&:key)).to include("Do you have a URN?")
        end

        it "does not show Nursery" do
          expect(subject.answers.map(&:key)).to_not include("Nursery")
        end
      end

      context "with urn" do
        let(:has_ofsted_urn) { "yes" }
        let(:institution_identifier) { private_childcare_provider.identifier }

        it "shows Ofsted registration details" do
          expect(subject.answers.map(&:key)).to include("Ofsted registration details")
        end

        it "does not show Do you have a URN?" do
          expect(subject.answers.map(&:key)).to_not include("Do you have a URN?")
        end

        it "does not show Nursery" do
          expect(subject.answers.map(&:key)).to_not include("Nursery")
        end
      end
    end
  end
end
