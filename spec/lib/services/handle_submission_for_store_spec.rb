require "rails_helper"

RSpec.describe Services::HandleSubmissionForStore do
  let(:user) { create(:user, trn: nil) }
  let(:school) { create(:school) }

  let(:store) do
    {
      "confirmed_email" => user.email,
      "trn_verified" => false,
      "trn" => "12345",
      "course_id" => Course.all.sample.id,
      "institution_identifier" => "School-#{school.urn}",
      "lead_provider_id" => LeadProvider.all.sample.id,
    }
  end

  subject { described_class.new(store: store) }

  describe "#call" do
    context "when entered trn is shorter than 7 characters" do
      it "pads by prefixing zeros to 7 characters" do
        subject.call

        expect(user.reload.trn).to eql("0012345")
      end
    end

    context "when there is a funding choice selected" do
      let(:store) do
        super().merge(
          "funding" => "school",
        )
      end

      context "when there is a funding choice selected and eligible for funding is true" do
        before do
          allow_any_instance_of(Services::FundingEligibility).to receive(:funding_eligiblity_status_code) { Services::FundingEligibility::FUNDED_ELIGIBILITY_RESULT }
        end

        it "clears the funding choice to nil on the application" do
          subject.call
          expect(user.applications.first.reload.funding_choice).to eq nil
        end
      end

      context "when there is a funding choice selected and eligible for funding is false" do
        before do
          allow_any_instance_of(Services::FundingEligibility).to receive(:funding_eligiblity_status_code) { Services::FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE }
        end

        it "saves the funding choice to nil on the application" do
          subject.call
          expect(user.applications.first.reload.funding_choice).to eq "school"
        end
      end
    end

    context "when applying for EHCO" do
      context "a headteacher for over five years" do
        let(:store) do
          {
            "confirmed_email" => user.email,
            "trn_verified" => false,
            "trn" => "12345",
            "course_id" => Course.ehco.first.id,
            "institution_identifier" => "School-#{school.urn}",
            "lead_provider_id" => LeadProvider.all.sample.id,
            "aso_headteacher" => "yes",
            "aso_new_headteacher" => "no",
          }
        end

        it "returns headteacher_status as yes_over_five_years" do
          subject.call
          expect(user.applications.first.reload.headteacher_status).to eq "yes_over_five_years"
        end
      end
    end
  end
end
