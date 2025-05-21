require "rails_helper"

RSpec.describe HandleSubmissionForStore do
  subject(:service) { described_class.new(store:) }

  let(:user_record_trn) { "0012345" }
  let(:user) { create(:user, trn: user_record_trn, full_name: "John Doe", ecf_id: nil) }
  let(:school) { create(:school, :funding_eligible_establishment_type_code) }
  let(:private_childcare_provider) { create(:private_childcare_provider, :on_early_years_register) }
  let(:cohort) { create(:cohort, :current) }
  let(:courses) { Course.where(identifier: "npq-leading-primary-mathematics") }
  let(:course) { courses.sample }
  let(:lead_provider) { LeadProvider.all.sample }

  let(:store) do
    {
      "current_user" => user,
      "course_identifier" => course.identifier,
      "institution_identifier" => "PrivateChildcareProvider-#{private_childcare_provider.provider_urn}",
      "lead_provider_id" => lead_provider.id,
      "works_in_childcare" => "yes",
      "works_in_school" => "no",
      "kind_of_nursery" => "private_nursery",
      "teacher_catchment" => "england",
    }
  end

  before do
    travel_to(Date.new(cohort.start_year, 9, 26))
  end

  describe "#call" do
    def stable_as_json(record)
      record.as_json(except: %i[id created_at updated_at significantly_updated_at updated_from_tra_at DEPRECATED_school_urn email_updates_status email_updates_unsubscribe_key])
    end

    context "when store includes information from the school path" do
      let(:store) do
        {
          "current_user" => user,
          "course_identifier" => course.identifier,
          "institution_identifier" => "School-#{school.urn}",
          "lead_provider_id" => lead_provider.id,
          "works_in_school" => "yes",
          "teacher_catchment" => "england",
          "work_setting" => "a_school",
          "referred_by_return_to_teaching_adviser" => "no",
          "senco_in_role" => "yes",
          "senco_start_date" => "2024-12-12",
          "trn" => "1234321",
        }
      end

      it "stores data from store" do
        expect(stable_as_json(user.reload)).to match({
          "email" => user.email,
          "ecf_id" => user.ecf_id,
          "trn" => "0012345",
          "full_name" => "John Doe",
          "provider" => nil,
          "raw_tra_provider_data" => nil,
          "date_of_birth" => 30.years.ago.to_date.to_s,
          "uid" => nil,
          "active_alert" => false,
          "archived_email" => nil,
          "archived_at" => nil,
          "get_an_identity_id_synced_to_ecf" => false,
          "national_insurance_number" => nil,
          "notify_user_for_future_reg" => false,
          "trn_auto_verified" => false,
          "trn_lookup_status" => nil,
          "trn_verified" => false,
          "feature_flag_id" => user.feature_flag_id,
        })
        expect(user.applications.reload.count).to eq 0
        expect(stable_as_json(user.applications.last)).to match(nil)

        subject.call

        expect(stable_as_json(user.reload)).to match({
          "email" => user.email,
          "ecf_id" => user.ecf_id,
          "trn" => "0012345",
          "full_name" => "John Doe",
          "date_of_birth" => 30.years.ago.to_date.to_s,
          "active_alert" => false,
          "archived_email" => nil,
          "archived_at" => nil,
          "get_an_identity_id_synced_to_ecf" => false,
          "national_insurance_number" => nil,
          "notify_user_for_future_reg" => false,
          "trn_auto_verified" => false,
          "trn_verified" => false,
          "trn_lookup_status" => nil,
          "feature_flag_id" => user.feature_flag_id,
          "provider" => nil,
          "raw_tra_provider_data" => nil,
          "uid" => nil,
        })
        expect(user.applications.reload.count).to eq 1
        last_application = user.applications.last
        expect(stable_as_json(last_application)).to match({
          "course_id" => course.id,
          "schedule_id" => nil,
          "ecf_id" => last_application.ecf_id,
          "eligible_for_funding" => true,
          "employer_name" => nil,
          "employment_type" => nil,
          "employment_role" => nil,
          "funded_place" => nil,
          "funding_choice" => nil,
          "funding_eligiblity_status_code" => "funded",
          "headteacher_status" => nil,
          "kind_of_nursery" => nil,
          "itt_provider_id" => nil,
          "DEPRECATED_itt_provider" => nil,
          "lead_mentor" => false,
          "lead_provider_approval_status" => "pending",
          "participant_outcome_state" => nil,
          "lead_provider_id" => lead_provider.id,
          "notes" => nil,
          "private_childcare_provider_id" => nil,
          "DEPRECATED_private_childcare_provider_urn" => nil,
          "cohort_id" => last_application.cohort_id,
          "school_id" => school.id,
          "targeted_delivery_funding_eligibility" => false,
          "targeted_support_funding_eligibility" => false,
          "teacher_catchment" => "england",
          "teacher_catchment_country" => "United Kingdom of Great Britain and Northern Ireland",
          "teacher_catchment_iso_country_code" => "GBR",
          "teacher_catchment_synced_to_ecf" => false,
          "training_status" => nil,
          "ukprn" => school.ukprn,
          "number_of_pupils" => nil,
          "primary_establishment" => false,
          "tsf_primary_eligibility" => false,
          "tsf_primary_plus_eligibility" => false,
          "user_id" => user.id,
          "works_in_nursery" => nil,
          "works_in_childcare" => false,
          "works_in_school" => true,
          "work_setting" => "a_school",
          "raw_application_data" => store.except("current_user"),
          "referred_by_return_to_teaching_adviser" => "no",
          "accepted_at" => nil,
          "senco_in_role" => "yes",
          "senco_start_date" => "2024-12-12",
          "on_submission_trn" => "1234321",
          "review_status" => nil,
        })
      end
    end

    context "when store includes information from the early years path" do
      let(:courses) { [Course.ehco] }
      let(:store) do
        {
          "current_user" => user,
          "course_identifier" => course.identifier,
          "institution_identifier" => "PrivateChildcareProvider-#{private_childcare_provider.provider_urn}",
          "lead_provider_id" => lead_provider.id,
          "works_in_childcare" => "yes",
          "works_in_school" => "no",
          "kind_of_nursery" => "private_nursery",
          "teacher_catchment" => "england",
          "work_setting" => "early_years_or_childcare",
          "referred_by_return_to_teaching_adviser" => "no",
          "senco_in_role" => nil,
          "senco_start_date" => nil,
          "on_submission_trn" => nil,
        }
      end

      it "stores data from store" do
        expect(stable_as_json(user.reload)).to match({
          "email" => user.email,
          "ecf_id" => user.ecf_id,
          "trn" => "0012345",
          "full_name" => "John Doe",
          "provider" => nil,
          "raw_tra_provider_data" => nil,
          "uid" => nil,
          "date_of_birth" => 30.years.ago.to_date.to_s,
          "active_alert" => false,
          "archived_email" => nil,
          "archived_at" => nil,
          "get_an_identity_id_synced_to_ecf" => false,
          "national_insurance_number" => nil,
          "notify_user_for_future_reg" => false,
          "trn_auto_verified" => false,
          "trn_lookup_status" => nil,
          "trn_verified" => false,
          "feature_flag_id" => user.feature_flag_id,
        })
        expect(user.applications.reload.count).to eq 0
        expect(stable_as_json(user.applications.last)).to match(nil)

        subject.call

        expect(stable_as_json(user.reload)).to match({
          "email" => user.email,
          "ecf_id" => user.ecf_id,
          "trn" => "0012345",
          "full_name" => "John Doe",
          "date_of_birth" => 30.years.ago.to_date.to_s,
          "active_alert" => false,
          "archived_email" => nil,
          "archived_at" => nil,
          "get_an_identity_id_synced_to_ecf" => false,
          "national_insurance_number" => nil,
          "notify_user_for_future_reg" => false,
          "trn_auto_verified" => false,
          "trn_verified" => false,
          "trn_lookup_status" => nil,
          "feature_flag_id" => user.feature_flag_id,
          "provider" => nil,
          "raw_tra_provider_data" => nil,
          "uid" => nil,
        })
        expect(user.applications.reload.count).to eq 1
        last_application = user.applications.last
        expect(stable_as_json(last_application)).to match({
          "course_id" => course.id,
          "schedule_id" => nil,
          "ecf_id" => last_application.ecf_id,
          "eligible_for_funding" => false,
          "employer_name" => nil,
          "employment_type" => nil,
          "employment_role" => nil,
          "funded_place" => nil,
          "funding_choice" => nil,
          "itt_provider_id" => nil,
          "DEPRECATED_itt_provider" => nil,
          "lead_mentor" => false,
          "lead_provider_approval_status" => "pending",
          "participant_outcome_state" => nil,
          "funding_eligiblity_status_code" => "early_years_invalid_npq",
          "headteacher_status" => nil,
          "lead_provider_id" => lead_provider.id,
          "notes" => nil,
          "kind_of_nursery" => "private_nursery",
          "private_childcare_provider_id" => private_childcare_provider.id,
          "DEPRECATED_private_childcare_provider_urn" => nil,
          "cohort_id" => last_application.cohort_id,
          "school_id" => nil,
          "targeted_delivery_funding_eligibility" => false,
          "targeted_support_funding_eligibility" => false,
          "teacher_catchment" => "england",
          "teacher_catchment_country" => "United Kingdom of Great Britain and Northern Ireland",
          "teacher_catchment_iso_country_code" => "GBR",
          "teacher_catchment_synced_to_ecf" => false,
          "training_status" => nil,
          "ukprn" => nil,
          "number_of_pupils" => 0,
          "primary_establishment" => false,
          "tsf_primary_eligibility" => false,
          "tsf_primary_plus_eligibility" => false,
          "user_id" => user.id,
          "works_in_nursery" => nil,
          "works_in_childcare" => true,
          "works_in_school" => false,
          "work_setting" => "early_years_or_childcare",
          "raw_application_data" => store.except("current_user"),
          "referred_by_return_to_teaching_adviser" => "no",
          "accepted_at" => nil,
          "senco_in_role" => nil,
          "senco_start_date" => nil,
          "on_submission_trn" => nil,
          "review_status" => nil,
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
          allow_any_instance_of(FundingEligibility).to receive(:funding_eligiblity_status_code).and_return(FundingEligibility::FUNDED_ELIGIBILITY_RESULT)
        end

        it "clears the funding choice to nil on the application" do
          subject.call
          expect(user.applications.first.reload.funding_choice).to be_nil
        end
      end

      context "when there is a funding choice selected and eligible for funding is false" do
        before do
          allow_any_instance_of(FundingEligibility).to receive(:funding_eligiblity_status_code).and_return(FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE)
        end

        it "saves the funding choice to school on the application" do
          subject.call
          expect(user.applications.first.reload.funding_choice).to eq "school"
        end

        context "when the course is EHCO" do
          before do
            allow_any_instance_of(FundingEligibility).to receive(:funding_eligiblity_status_code).and_return(FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE)
          end

          let(:courses) { [Course.ehco] }

          let(:store) do
            super().merge(
              "funding" => "school",
              "ehco_funding_choice" => "trust",
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
            "course_identifier" => ehco_course.identifier,
            "institution_identifier" => "School-#{school.urn}",
            "lead_provider_id" => LeadProvider.all.sample.id,
            "ehco_headteacher" => "yes",
            "ehco_new_headteacher" => "no",
          }
        end

        let(:ehco_course) { Course.ehco }

        it "applies the correct course" do
          subject.call
          expect(user.applications.first.course).to eq(ehco_course)
        end
      end

      context "a headteacher for over five years" do
        let(:store) do
          {
            "current_user" => user,
            "course_identifier" => Course.ehco.identifier,
            "institution_identifier" => "School-#{school.urn}",
            "lead_provider_id" => LeadProvider.all.sample.id,
            "ehco_headteacher" => "yes",
            "ehco_new_headteacher" => "no",
          }
        end

        it "returns headteacher_status as yes_over_five_years" do
          subject.call
          expect(user.applications.first.reload.headteacher_status).to eq "yes_over_five_years"
        end
      end

      it "enqueues SendApplicationSubmissionEmailJob" do
        expect { subject.call }.to have_enqueued_job(SendApplicationSubmissionEmailJob).exactly(:once).on_queue("default")
      end
    end

    context "when teacher catchment is not in the UK catchment area" do
      let(:store) do
        {
          "current_user" => user,
          "course_identifier" => course.identifier,
          "institution_identifier" => "PrivateChildcareProvider-#{private_childcare_provider.provider_urn}",
          "lead_provider_id" => lead_provider.id,
          "works_in_childcare" => "yes",
          "works_in_school" => "no",
          "kind_of_nursery" => "private_nursery",
          "teacher_catchment" => "another",
          "teacher_catchment_country" => "spain",
          "work_setting" => "early_years_or_childcare",
          "referred_by_return_to_teaching_adviser" => "no",
          "senco_in_role" => nil,
          "senco_start_date" => nil,
          "on_submission_trn" => nil,
        }
      end

      it "stores data from store" do
        subject.call

        expect(stable_as_json(user.applications.last)).to match({
          "course_id" => course.id,
          "schedule_id" => nil,
          "ecf_id" => user.applications.last.ecf_id,
          "eligible_for_funding" => false,
          "employer_name" => nil,
          "employment_type" => nil,
          "employment_role" => nil,
          "funded_place" => nil,
          "funding_choice" => nil,
          "funding_eligiblity_status_code" => "not_in_england",
          "headteacher_status" => nil,
          "kind_of_nursery" => "private_nursery",
          "itt_provider_id" => nil,
          "DEPRECATED_itt_provider" => nil,
          "lead_mentor" => false,
          "lead_provider_approval_status" => "pending",
          "participant_outcome_state" => nil,
          "lead_provider_id" => lead_provider.id,
          "notes" => nil,
          "private_childcare_provider_id" => nil,
          "DEPRECATED_private_childcare_provider_urn" => nil,
          "cohort_id" => cohort.id,
          "school_id" => nil,
          "targeted_delivery_funding_eligibility" => false,
          "targeted_support_funding_eligibility" => false,
          "teacher_catchment" => "another",
          "teacher_catchment_country" => "spain",
          "teacher_catchment_iso_country_code" => "ESP",
          "teacher_catchment_synced_to_ecf" => false,
          "training_status" => nil,
          "ukprn" => nil,
          "number_of_pupils" => 0,
          "primary_establishment" => false,
          "tsf_primary_eligibility" => false,
          "tsf_primary_plus_eligibility" => false,
          "user_id" => user.id,
          "works_in_nursery" => nil,
          "works_in_childcare" => true,
          "works_in_school" => false,
          "work_setting" => "early_years_or_childcare",
          "raw_application_data" => store.except("current_user"),
          "referred_by_return_to_teaching_adviser" => "no",
          "accepted_at" => nil,
          "senco_in_role" => nil,
          "senco_start_date" => nil,
          "on_submission_trn" => nil,
          "review_status" => nil,
        })
      end
    end

    context "when teacher catchment is empty" do
      let(:store) do
        {
          "current_user" => user,
          "course_identifier" => course.identifier,
          "institution_identifier" => "PrivateChildcareProvider-#{private_childcare_provider.provider_urn}",
          "lead_provider_id" => lead_provider.id,
          "works_in_childcare" => "yes",
          "works_in_school" => "no",
          "kind_of_nursery" => "private_nursery",
          "teacher_catchment" => nil,
          "teacher_catchment_country" => nil,
          "work_setting" => "early_years_or_childcare",
          "referred_by_return_to_teaching_adviser" => "no",
          "senco_in_role" => nil,
          "senco_start_date" => nil,
          "on_submission_trn" => nil,
        }
      end

      it "stores data from store" do
        subject.call

        expect(stable_as_json(user.applications.last)).to match({
          "course_id" => course.id,
          "schedule_id" => nil,
          "ecf_id" => user.applications.last.ecf_id,
          "eligible_for_funding" => false,
          "employer_name" => nil,
          "employment_type" => nil,
          "employment_role" => nil,
          "funded_place" => nil,
          "funding_choice" => nil,
          "funding_eligiblity_status_code" => "not_in_england",
          "headteacher_status" => nil,
          "kind_of_nursery" => "private_nursery",
          "itt_provider_id" => nil,
          "DEPRECATED_itt_provider" => nil,
          "lead_mentor" => false,
          "lead_provider_approval_status" => "pending",
          "participant_outcome_state" => nil,
          "lead_provider_id" => lead_provider.id,
          "notes" => nil,
          "private_childcare_provider_id" => nil,
          "DEPRECATED_private_childcare_provider_urn" => nil,
          "cohort_id" => cohort.id,
          "school_id" => nil,
          "targeted_delivery_funding_eligibility" => false,
          "targeted_support_funding_eligibility" => false,
          "teacher_catchment" => nil,
          "teacher_catchment_country" => nil,
          "teacher_catchment_iso_country_code" => nil,
          "teacher_catchment_synced_to_ecf" => false,
          "training_status" => nil,
          "ukprn" => nil,
          "number_of_pupils" => 0,
          "primary_establishment" => false,
          "tsf_primary_eligibility" => false,
          "tsf_primary_plus_eligibility" => false,
          "user_id" => user.id,
          "works_in_nursery" => nil,
          "works_in_childcare" => true,
          "works_in_school" => false,
          "work_setting" => "early_years_or_childcare",
          "raw_application_data" => store.except("current_user"),
          "referred_by_return_to_teaching_adviser" => "no",
          "accepted_at" => nil,
          "senco_in_role" => nil,
          "senco_start_date" => nil,
          "on_submission_trn" => nil,
          "review_status" => nil,
        })
      end
    end

    context "when teacher catchment is not found" do
      before do
        allow(Sentry).to receive(:capture_message)
      end

      let(:store) do
        {
          "current_user" => user,
          "course_identifier" => course.identifier,
          "institution_identifier" => "PrivateChildcareProvider-#{private_childcare_provider.provider_urn}",
          "lead_provider_id" => lead_provider.id,
          "works_in_childcare" => "yes",
          "works_in_school" => "no",
          "kind_of_nursery" => "private_nursery",
          "teacher_catchment" => "another",
          "teacher_catchment_country" => "wonderland",
          "work_setting" => "early_years_or_childcare",
          "referred_by_return_to_teaching_adviser" => "no",
          "senco_in_role" => nil,
          "senco_start_date" => nil,
          "on_submission_trn" => nil,
        }
      end

      it "logs an error" do
        subject.call

        expect(Sentry).to have_received(:capture_message).with("Could not find the ISO3166 alpha3 code for wonderland.", level: :warning)
      end

      it "stores data from store" do
        subject.call

        expect(stable_as_json(user.applications.last)).to match({
          "course_id" => course.id,
          "schedule_id" => nil,
          "ecf_id" => user.applications.last.ecf_id,
          "eligible_for_funding" => false,
          "employer_name" => nil,
          "employment_type" => nil,
          "employment_role" => nil,
          "funded_place" => nil,
          "funding_choice" => nil,
          "funding_eligiblity_status_code" => "not_in_england",
          "headteacher_status" => nil,
          "kind_of_nursery" => "private_nursery",
          "itt_provider_id" => nil,
          "DEPRECATED_itt_provider" => nil,
          "lead_mentor" => false,
          "lead_provider_approval_status" => "pending",
          "participant_outcome_state" => nil,
          "lead_provider_id" => lead_provider.id,
          "notes" => nil,
          "private_childcare_provider_id" => nil,
          "DEPRECATED_private_childcare_provider_urn" => nil,
          "cohort_id" => cohort.id,
          "school_id" => nil,
          "targeted_delivery_funding_eligibility" => false,
          "targeted_support_funding_eligibility" => false,
          "teacher_catchment" => "another",
          "teacher_catchment_country" => "wonderland",
          "teacher_catchment_iso_country_code" => nil,
          "teacher_catchment_synced_to_ecf" => false,
          "training_status" => nil,
          "ukprn" => nil,
          "number_of_pupils" => 0,
          "primary_establishment" => false,
          "tsf_primary_eligibility" => false,
          "tsf_primary_plus_eligibility" => false,
          "user_id" => user.id,
          "works_in_nursery" => nil,
          "works_in_childcare" => true,
          "works_in_school" => false,
          "work_setting" => "early_years_or_childcare",
          "raw_application_data" => store.except("current_user"),
          "referred_by_return_to_teaching_adviser" => "no",
          "accepted_at" => nil,
          "senco_in_role" => nil,
          "senco_start_date" => nil,
          "on_submission_trn" => nil,
          "review_status" => nil,
        })
      end
    end

    describe "#review_status" do
      subject { application.review_status }

      let(:store) { build :registration_wizard_store }
      let(:application) { service.tap(&:call).application }

      it { is_expected.to be_nil }

      context "when referred_by_return_to_teaching_adviser is set" do
        let :store do
          build :registration_wizard_store, referred_by_return_to_teaching_adviser: "yes"
        end

        it { is_expected.to eq "needs_review" }
      end

      %w[
        hospital_school
        lead_mentor_for_accredited_itt_provider
        local_authority_supply_teacher
        local_authority_virtual_school
        young_offender_institution
        other
      ].each do |employment_type|
        context "when employment_type is set to #{employment_type}" do
          let :store do
            build :registration_wizard_store, employment_type:,
                                              work_setting: "another_setting"
          end

          it { is_expected.to eq "needs_review" }
        end
      end

      context "when employment_type is set to a non in-review type" do
        let :store do
          build :registration_wizard_store, employment_type: "something else",
                                            work_setting: "another_setting"
        end

        it { is_expected.to be_nil }
      end

      context "when employment_type is not relevant" do
        let :store do
          build :registration_wizard_store, employment_type: "hospital_school",
                                            work_setting: "early_years_or_childcare"
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
