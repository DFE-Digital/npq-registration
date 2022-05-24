require "rails_helper"

RSpec.describe Services::HandleSubmissionForStore do
  let(:user) { create(:user, trn: nil) }
  let(:school) { create(:school) }
  let(:private_childcare_provider) { create(:private_childcare_provider, :on_early_years_register) }

  let(:courses) { Course.all - Course.ehco }

  let(:course) { courses.sample }
  let(:lead_provider) { LeadProvider.all.sample }

  let(:store) do
    {
      "confirmed_email" => user.email,
      "trn_verified" => false,
      "trn" => "12345",
      "course_id" => course.id,
      "institution_identifier" => "PrivateChildcareProvider-#{private_childcare_provider.provider_urn}",
      "lead_provider_id" => lead_provider.id,
      "date_of_birth" => "1992-05-24",
      "full_name" => "Jane Doe",
      "works_in_childcare" => "yes",
      "works_in_nursery" => "yes",
      "works_in_school" => "no",
      "kind_of_nursery" => "private_nursery",
      "teacher_catchment" => "england",
    }
  end

  subject { described_class.new(store: store) }

  describe "#call" do
    def stable_as_json(record)
      record.as_json(except: %i[id created_at updated_at])
    end

    it "store data from store" do
      expect(stable_as_json(user.reload)).to match({
        "email" => "user1@example.com",
        "ecf_id" => nil,
        "trn" => nil,
        "full_name" => "John Doe",
        "otp_hash" => nil,
        "otp_expires_at" => nil,
        "date_of_birth" => "1992-05-23",
        "trn_verified" => false,
        "active_alert" => false,
        "national_insurance_number" => nil,
        "trn_auto_verified" => false,
        "admin" => false,
      })
      expect(user.applications.reload.count).to eq 0
      expect(stable_as_json(user.applications.last)).to match(nil)

      subject.call

      expect(stable_as_json(user.reload)).to match({
        "email" => "user1@example.com",
        "ecf_id" => nil,
        "trn" => "0012345",
        "full_name" => "Jane Doe",
        "otp_hash" => nil,
        "otp_expires_at" => nil,
        "date_of_birth" => "1992-05-24",
        "trn_verified" => false,
        "active_alert" => nil,
        "national_insurance_number" => nil,
        "trn_auto_verified" => false,
        "admin" => false,
      })
      expect(user.applications.reload.count).to eq 1
      expect(stable_as_json(user.applications.last)).to match({
        "cohort" => 2022,
        "course_id" => course.id,
        "ecf_id" => nil,
        "eligible_for_funding" => false,
        "employer_name" => nil,
        "employment_role" => nil,
        "funding_choice" => nil,
        "funding_eligiblity_status_code" => "early_years_invalid_npq",
        "headteacher_status" => nil,
        "kind_of_nursery" => "private_nursery",
        "lead_provider_id" => lead_provider.id,
        "private_childcare_provider_urn" => "100001",
        "school_urn" => nil,
        "targeted_delivery_funding_eligibility" => false,
        "targeted_support_funding_eligibility" => false,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "ukprn" => nil,
        "user_id" => user.id,
        "works_in_childcare" => true,
        "works_in_nursery" => true,
        "works_in_school" => false,
      })
    end

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

        it "saves the funding choice to school on the application" do
          subject.call
          expect(user.applications.first.reload.funding_choice).to eq "school"
        end

        context "when the course is EHCO" do
          before do
            allow_any_instance_of(Services::FundingEligibility).to receive(:funding_eligiblity_status_code) { Services::FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE }
          end

          let(:courses) { Course.ehco }

          let(:store) do
            super().merge(
              "funding" => "school",
              "aso_funding_choice" => "trust",
            )
          end

          it "saves funding choice from the aso funding choice question instead of the regular path" do
            subject.call
            expect(user.applications.first.reload.funding_choice).to eq "trust"
          end
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
