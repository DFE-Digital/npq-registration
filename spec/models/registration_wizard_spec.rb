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
        }
      end

      it "shows ASO funding option" do
        expect(subject.answers.find { |el| el.key == "How is the Additional Support Offer being paid for?" }.value).to eql("The Additional Support Offer is being paid in another way")
      end
    end
  end
end
