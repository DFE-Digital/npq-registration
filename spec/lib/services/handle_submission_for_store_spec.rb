require "rails_helper"

RSpec.describe Services::HandleSubmissionForStore do
  context "when TRA feature flag is disabled" do
    before do
      allow(Flipper).to receive(:enabled?).and_call_original
      allow(Flipper).to receive(:enabled?).with(Services::Feature::GAI_INTEGRATION_KEY, anything).and_return(false)
    end

    let(:user) { create(:user, trn: nil) }
    let(:school) { create(:school, :funding_eligible_establishment_type_code) }
    let(:private_childcare_provider) { create(:private_childcare_provider, :on_early_years_register) }

    let(:courses) { Course.all - Course.ehco - Course.aso }

    let(:course) { courses.sample }
    let(:present_course_name) { Course::DISPLAY_NAME_MAPPING.key(course.name) }
    let(:lead_provider) { LeadProvider.all.sample }

    let(:store) do
      {
        "current_user" => user,
        "confirmed_email" => user.email,
        "trn_verified" => false,
        "trn" => "12345",
        "course_id" => course.id,
        "institution_identifier" => "PrivateChildcareProvider-#{private_childcare_provider.provider_urn}",
        "lead_provider_id" => lead_provider.id,
        "date_of_birth" => (30.years.ago + 1.day).to_s,
        "full_name" => "Jane Doe",
        "works_in_childcare" => "yes",
        "works_in_school" => "no",
        "kind_of_nursery" => "private_nursery",
        "teacher_catchment" => "england",
        "choose_your_npq" => present_course_name,
      }
    end

    before do
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/12345?npq_course_identifier=#{course.identifier}")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
        )
        .to_return(
          status: 200,
          body: ecf_funding_lookup_response(previously_funded: false),
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )
    end

    subject { described_class.new(store:) }

    describe "#call" do
      def stable_as_json(record)
        record.as_json(except: %i[id created_at updated_at])
      end

      context "when store includes information from the school path" do
        let(:store) do
          {
            "current_user" => user,
            "confirmed_email" => user.email,
            "trn_verified" => false,
            "trn" => "12345",
            "course_id" => course.id,
            "institution_identifier" => "School-#{school.urn}",
            "lead_provider_id" => lead_provider.id,
            "date_of_birth" => (30.years.ago + 1.day).to_s,
            "full_name" => "Jane Doe",
            "works_in_school" => "yes",
            "teacher_catchment" => "england",
            "work_setting" => "a_school",
            "choose_your_npq" => present_course_name,
          }
        end

        it "store data from store" do
          expect(stable_as_json(user.reload)).to match({
            "email" => user.email,
            "ecf_id" => nil,
            "trn" => nil,
            "full_name" => "John Doe",
            "otp_hash" => nil,
            "otp_expires_at" => nil,
            "date_of_birth" => 30.years.ago.to_date.to_s,
            "trn_verified" => false,
            "active_alert" => false,
            "get_an_identity_id_synced_to_ecf" => false,
            "national_insurance_number" => nil,
            "trn_auto_verified" => false,
            "admin" => false,
            "feature_flag_id" => user.feature_flag_id,
            "flipper_admin_access" => false,
            "provider" => nil,
            "raw_tra_provider_data" => nil,
            "uid" => nil,
          })
          expect(user.applications.reload.count).to eq 0
          expect(stable_as_json(user.applications.last)).to match(nil)

          subject.call

          expect(stable_as_json(user.reload)).to match({
            "email" => user.email,
            "ecf_id" => nil,
            "trn" => "0012345",
            "full_name" => "Jane Doe",
            "otp_hash" => nil,
            "otp_expires_at" => nil,
            "date_of_birth" => (30.years.ago + 1.day).to_date.to_s,
            "trn_verified" => false,
            "active_alert" => nil,
            "get_an_identity_id_synced_to_ecf" => false,
            "national_insurance_number" => nil,
            "trn_auto_verified" => false,
            "admin" => false,
            "feature_flag_id" => user.feature_flag_id,
            "flipper_admin_access" => false,
            "provider" => nil,
            "raw_tra_provider_data" => nil,
            "uid" => nil,
          })
          expect(user.applications.reload.count).to eq 1
          expect(stable_as_json(user.applications.last)).to match({
            "cohort" => 2022,
            "course_id" => course.id,
            "ecf_id" => nil,
            "eligible_for_funding" => true,
            "employer_name" => nil,
            "employment_type" => nil,
            "employment_role" => nil,
            "funding_choice" => nil,
            "funding_eligiblity_status_code" => "funded",
            "headteacher_status" => nil,
            "kind_of_nursery" => nil,
            "works_in_nursery" => nil,
            "lead_provider_id" => lead_provider.id,
            "private_childcare_provider_urn" => nil,
            "school_urn" => school.urn,
            "targeted_delivery_funding_eligibility" => false,

            "teacher_catchment" => "england",
            "teacher_catchment_country" => nil,
            "teacher_catchment_synced_to_ecf" => false,
            "ukprn" => nil,
            "user_id" => user.id,
            "works_in_childcare" => false,
            "works_in_school" => true,
            "work_setting" => "a_school",
            "raw_application_data" => store.except("current_user"),
          })
        end
      end

      context "when store includes information from the early years path" do
        let(:courses) { Course.ehco }
        let(:store) do
          {
            "current_user" => user,
            "confirmed_email" => user.email,
            "trn_verified" => false,
            "trn" => "12345",
            "course_id" => course.id,
            "institution_identifier" => "PrivateChildcareProvider-#{private_childcare_provider.provider_urn}",
            "lead_provider_id" => lead_provider.id,
            "date_of_birth" => (30.years.ago + 1.day).to_s,
            "full_name" => "Jane Doe",
            "works_in_childcare" => "yes",
            "works_in_school" => "no",
            "kind_of_nursery" => "private_nursery",
            "teacher_catchment" => "england",
            "work_setting" => "early_years_or_childcare",
            "choose_your_npq" => present_course_name,
          }
        end

        it "store data from store" do
          expect(stable_as_json(user.reload)).to match({
            "email" => user.email,
            "ecf_id" => nil,
            "trn" => nil,
            "full_name" => "John Doe",
            "otp_hash" => nil,
            "otp_expires_at" => nil,
            "date_of_birth" => 30.years.ago.to_date.to_s,
            "trn_verified" => false,
            "active_alert" => false,
            "get_an_identity_id_synced_to_ecf" => false,
            "national_insurance_number" => nil,
            "trn_auto_verified" => false,
            "admin" => false,
            "feature_flag_id" => user.feature_flag_id,
            "flipper_admin_access" => false,
            "provider" => nil,
            "raw_tra_provider_data" => nil,
            "uid" => nil,
          })
          expect(user.applications.reload.count).to eq 0
          expect(stable_as_json(user.applications.last)).to match(nil)

          subject.call

          expect(stable_as_json(user.reload)).to match({
            "email" => user.email,
            "ecf_id" => nil,
            "trn" => "0012345",
            "full_name" => "Jane Doe",
            "otp_hash" => nil,
            "otp_expires_at" => nil,
            "date_of_birth" => (30.years.ago + 1.day).to_date.to_s,
            "trn_verified" => false,
            "active_alert" => nil,
            "get_an_identity_id_synced_to_ecf" => false,
            "national_insurance_number" => nil,
            "trn_auto_verified" => false,
            "admin" => false,
            "feature_flag_id" => user.feature_flag_id,
            "flipper_admin_access" => false,
            "provider" => nil,
            "raw_tra_provider_data" => nil,
            "uid" => nil,
          })
          expect(user.applications.reload.count).to eq 1
          expect(stable_as_json(user.applications.last)).to match({
            "cohort" => 2022,
            "course_id" => course.id,
            "ecf_id" => nil,
            "eligible_for_funding" => false,
            "employer_name" => nil,
            "employment_type" => nil,
            "employment_role" => nil,
            "funding_choice" => nil,
            "funding_eligiblity_status_code" => "early_years_invalid_npq",
            "headteacher_status" => nil,
            "lead_provider_id" => lead_provider.id,
            "works_in_nursery" => nil,
            "kind_of_nursery" => "private_nursery",
            "private_childcare_provider_urn" => private_childcare_provider.provider_urn,
            "school_urn" => nil,
            "targeted_delivery_funding_eligibility" => false,

            "teacher_catchment" => "england",
            "teacher_catchment_country" => nil,
            "teacher_catchment_synced_to_ecf" => false,
            "ukprn" => nil,
            "user_id" => user.id,
            "works_in_childcare" => true,
            "works_in_school" => false,
            "work_setting" => "early_years_or_childcare",
            "raw_application_data" => store.except("current_user"),
          })
        end
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
        context "happy path" do
          let(:store) do
            {
              "current_user" => user,
              "confirmed_email" => user.email,
              "trn_verified" => false,
              "trn" => "12345",
              "course_id" => Course.ehco.first.id,
              "institution_identifier" => "School-#{school.urn}",
              "lead_provider_id" => LeadProvider.all.sample.id,
              "aso_headteacher" => "yes",
              "aso_new_headteacher" => "no",
              "choose_your_npq" => present_course_name,
            }
          end

          it "applies 2021 cohort" do
            subject.call
            expect(user.applications.first.cohort).to eql(2022)
          end
        end

        context "a headteacher for over five years" do
          let(:store) do
            {
              "current_user" => user,
              "confirmed_email" => user.email,
              "trn_verified" => false,
              "trn" => "12345",
              "course_id" => Course.ehco.first.id,
              "institution_identifier" => "School-#{school.urn}",
              "lead_provider_id" => LeadProvider.all.sample.id,
              "aso_headteacher" => "yes",
              "aso_new_headteacher" => "no",
              "choose_your_npq" => present_course_name,
            }
          end

          before do
            stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/12345?npq_course_identifier=npq-early-headship-coaching-offer")
              .with(
                headers: {
                  "Authorization" => "Bearer ECFAPPBEARERTOKEN",
                },
              )
              .to_return(
                status: 200,
                body: ecf_funding_lookup_response(previously_funded: false),
                headers: {
                  "Content-Type" => "application/vnd.api+json",
                },
              )
          end

          it "returns headteacher_status as yes_over_five_years" do
            subject.call
            expect(user.applications.first.reload.headteacher_status).to eq "yes_over_five_years"
          end
        end
      end
    end
  end

  context "when TRA feature flag is enabled" do
    before do
      allow(Flipper).to receive(:enabled?).and_call_original
      allow(Flipper).to receive(:enabled?).with(Services::Feature::GAI_INTEGRATION_KEY, anything).and_return(true)
    end

    let(:user_record_trn) { "0012345" }
    let(:user) { create(:user, trn: user_record_trn) }
    let(:school) { create(:school, :funding_eligible_establishment_type_code) }
    let(:private_childcare_provider) { create(:private_childcare_provider, :on_early_years_register) }

    let(:courses) { Course.all - Course.ehco - Course.aso }

    let(:course) { courses.sample }
    let(:present_course_name) { Course::DISPLAY_NAME_MAPPING.key(course.name) }
    let(:lead_provider) { LeadProvider.all.sample }

    let(:store) do
      {
        "current_user" => user,
        "course_id" => course.id,
        "institution_identifier" => "PrivateChildcareProvider-#{private_childcare_provider.provider_urn}",
        "lead_provider_id" => lead_provider.id,
        "works_in_childcare" => "yes",
        "works_in_school" => "no",
        "kind_of_nursery" => "private_nursery",
        "teacher_catchment" => "england",
        "choose_your_npq" => present_course_name,
      }
    end

    before do
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/0012345?npq_course_identifier=#{course.identifier}")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
        )
        .to_return(
          status: 200,
          body: ecf_funding_lookup_response(previously_funded: false),
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )
    end

    subject { described_class.new(store:) }

    describe "#call" do
      def stable_as_json(record)
        record.as_json(except: %i[id created_at updated_at])
      end

      context "when store includes information from the school path" do
        let(:store) do
          {
            "current_user" => user,
            "course_id" => course.id,
            "institution_identifier" => "School-#{school.urn}",
            "lead_provider_id" => lead_provider.id,
            "works_in_school" => "yes",
            "teacher_catchment" => "england",
            "work_setting" => "a_school",
            "choose_your_npq" => present_course_name,
          }
        end

        it "store data from store" do
          expect(stable_as_json(user.reload)).to match({
            "email" => user.email,
            "ecf_id" => nil,
            "trn" => "0012345",
            "full_name" => "John Doe",
            "otp_hash" => nil,
            "otp_expires_at" => nil,
            "provider" => nil,
            "raw_tra_provider_data" => nil,
            "date_of_birth" => 30.years.ago.to_date.to_s,
            "uid" => nil,
            "active_alert" => false,
            "get_an_identity_id_synced_to_ecf" => false,
            "national_insurance_number" => nil,
            "trn_auto_verified" => false,
            "trn_verified" => false,
            "admin" => false,
            "feature_flag_id" => user.feature_flag_id,
            "flipper_admin_access" => false,
          })
          expect(user.applications.reload.count).to eq 0
          expect(stable_as_json(user.applications.last)).to match(nil)

          subject.call

          expect(stable_as_json(user.reload)).to match({
            "email" => user.email,
            "ecf_id" => nil,
            "trn" => "0012345",
            "full_name" => "John Doe",
            "otp_hash" => nil,
            "otp_expires_at" => nil,
            "date_of_birth" => 30.years.ago.to_date.to_s,
            "active_alert" => nil,
            "get_an_identity_id_synced_to_ecf" => false,
            "national_insurance_number" => nil,
            "trn_auto_verified" => false,
            "trn_verified" => false,
            "admin" => false,
            "feature_flag_id" => user.feature_flag_id,
            "flipper_admin_access" => false,
            "provider" => nil,
            "raw_tra_provider_data" => nil,
            "uid" => nil,
          })
          expect(user.applications.reload.count).to eq 1
          expect(stable_as_json(user.applications.last)).to match({
            "cohort" => 2022,
            "course_id" => course.id,
            "ecf_id" => nil,
            "eligible_for_funding" => true,
            "employer_name" => nil,
            "employment_type" => nil,
            "employment_role" => nil,
            "funding_choice" => nil,
            "funding_eligiblity_status_code" => "funded",
            "headteacher_status" => nil,
            "kind_of_nursery" => nil,
            "lead_provider_id" => lead_provider.id,
            "private_childcare_provider_urn" => nil,
            "school_urn" => school.urn,
            "targeted_delivery_funding_eligibility" => false,

            "teacher_catchment" => "england",
            "teacher_catchment_country" => nil,
            "teacher_catchment_synced_to_ecf" => false,
            "ukprn" => nil,
            "user_id" => user.id,
            "works_in_nursery" => nil,
            "works_in_childcare" => false,
            "works_in_school" => true,
            "work_setting" => "a_school",
            "raw_application_data" => store.except("current_user"),
          })
        end
      end

      context "when store includes information from the early years path" do
        let(:courses) { Course.ehco }
        let(:store) do
          {
            "current_user" => user,
            "course_id" => course.id,
            "institution_identifier" => "PrivateChildcareProvider-#{private_childcare_provider.provider_urn}",
            "lead_provider_id" => lead_provider.id,
            "works_in_childcare" => "yes",
            "works_in_school" => "no",
            "kind_of_nursery" => "private_nursery",
            "teacher_catchment" => "england",
            "work_setting" => "early_years_or_childcare",
            "choose_your_npq" => present_course_name,
          }
        end

        it "store data from store" do
          expect(stable_as_json(user.reload)).to match({
            "email" => user.email,
            "ecf_id" => nil,
            "trn" => "0012345",
            "full_name" => "John Doe",
            "otp_hash" => nil,
            "provider" => nil,
            "raw_tra_provider_data" => nil,
            "uid" => nil,
            "otp_expires_at" => nil,
            "date_of_birth" => 30.years.ago.to_date.to_s,
            "active_alert" => false,
            "get_an_identity_id_synced_to_ecf" => false,
            "national_insurance_number" => nil,
            "trn_auto_verified" => false,
            "trn_verified" => false,
            "admin" => false,
            "feature_flag_id" => user.feature_flag_id,
            "flipper_admin_access" => false,
          })
          expect(user.applications.reload.count).to eq 0
          expect(stable_as_json(user.applications.last)).to match(nil)

          subject.call

          expect(stable_as_json(user.reload)).to match({
            "email" => user.email,
            "ecf_id" => nil,
            "trn" => "0012345",
            "full_name" => "John Doe",
            "otp_hash" => nil,
            "otp_expires_at" => nil,
            "date_of_birth" => 30.years.ago.to_date.to_s,
            "active_alert" => nil,
            "get_an_identity_id_synced_to_ecf" => false,
            "national_insurance_number" => nil,
            "trn_auto_verified" => false,
            "trn_verified" => false,
            "admin" => false,
            "feature_flag_id" => user.feature_flag_id,
            "flipper_admin_access" => false,
            "provider" => nil,
            "raw_tra_provider_data" => nil,
            "uid" => nil,
          })
          expect(user.applications.reload.count).to eq 1
          expect(stable_as_json(user.applications.last)).to match({
            "cohort" => 2022,
            "course_id" => course.id,
            "ecf_id" => nil,
            "eligible_for_funding" => false,
            "employer_name" => nil,
            "employment_type" => nil,
            "employment_role" => nil,
            "funding_choice" => nil,
            "funding_eligiblity_status_code" => "early_years_invalid_npq",
            "headteacher_status" => nil,
            "lead_provider_id" => lead_provider.id,
            "kind_of_nursery" => "private_nursery",
            "private_childcare_provider_urn" => private_childcare_provider.provider_urn,
            "school_urn" => nil,
            "targeted_delivery_funding_eligibility" => false,

            "teacher_catchment" => "england",
            "teacher_catchment_country" => nil,
            "teacher_catchment_synced_to_ecf" => false,
            "ukprn" => nil,
            "user_id" => user.id,
            "works_in_nursery" => nil,
            "works_in_childcare" => true,
            "works_in_school" => false,
            "work_setting" => "early_years_or_childcare",
            "raw_application_data" => store.except("current_user"),
          })
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
        context "happy path" do
          let(:store) do
            {
              "current_user" => user,
              "course_id" => Course.ehco.first.id,
              "institution_identifier" => "School-#{school.urn}",
              "lead_provider_id" => LeadProvider.all.sample.id,
              "aso_headteacher" => "yes",
              "aso_new_headteacher" => "no",
              "choose_your_npq" => present_course_name,
            }
          end

          it "applies 2021 cohort" do
            subject.call
            expect(user.applications.first.cohort).to eql(2022)
          end
        end

        context "a headteacher for over five years" do
          let(:store) do
            {
              "current_user" => user,
              "course_id" => Course.ehco.first.id,
              "institution_identifier" => "School-#{school.urn}",
              "lead_provider_id" => LeadProvider.all.sample.id,
              "aso_headteacher" => "yes",
              "aso_new_headteacher" => "no",
              "choose_your_npq" => present_course_name,
            }
          end

          before do
            stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/12345?npq_course_identifier=npq-early-headship-coaching-offer")
              .with(
                headers: {
                  "Authorization" => "Bearer ECFAPPBEARERTOKEN",
                },
              )
              .to_return(
                status: 200,
                body: ecf_funding_lookup_response(previously_funded: false),
                headers: {
                  "Content-Type" => "application/vnd.api+json",
                },
              )
          end

          it "returns headteacher_status as yes_over_five_years" do
            subject.call
            expect(user.applications.first.reload.headteacher_status).to eq "yes_over_five_years"
          end
        end
      end
    end
  end
end
