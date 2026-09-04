require "rails_helper"

RSpec.describe Questionnaires::CheckAnswersAndSubmit do
  subject(:instance) { described_class.new(wizard:) }

  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:session) { {} }
  let(:current_user) { build(:user) }
  let(:store) { {} }
  let(:funding_eligibility_calculator) { instance_double(FundingEligibility, funding_eligiblity_status_code: calculated_funding_eligiblity_status_code) }
  let(:calculated_funding_eligiblity_status_code) { nil }
  let(:course) { create(:course) }

  let(:wizard) do
    RegistrationWizard.new(
      current_step: :check_answers_and_submit,
      store:,
      request:,
      current_user:,
    )
  end

  before { allow(FundingEligibility).to receive(:new_from_query_store).and_return(funding_eligibility_calculator) }

  describe "#requirements_met?" do
    subject { instance.requirements_met? }

    minimum_answers_keys = %w[
      course_start_cohort
      course_identifier
      work_setting
      lead_provider_id
      can_share_choices
      funding_eligiblity_status_code
    ]

    let(:minimum_answers) do
      {
        course_start_cohort: Questionnaires::CourseStartDate::OPTIONS.keys.first,
        course_identifier: course.identifier,
        work_setting: Questionnaires::WorkSetting::NESTED_SCHOOL_SETTINGS.first,
        lead_provider_id: LeadProvider.first.id,
        can_share_choices: "1",
        funding_eligiblity_status_code: FundingEligibility::FUNDED_ELIGIBILITY_RESULT,
      }.stringify_keys
    end

    context "when the minimum set of answers is present" do
      let(:store) { minimum_answers }

      it { is_expected.to be true }
    end

    minimum_answers_keys.each do |missing_key|
      context "when the #{missing_key} is missing" do
        let(:store) { minimum_answers.except(missing_key) }

        it { is_expected.to be false }
      end
    end

    context "when the application is not eligible" do
      let(:store) do
        minimum_answers
          .merge(funding_eligiblity_status_code: FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE,
                 funding:)
          .stringify_keys
      end

      context "when the funding answer is present" do
        let(:funding) { "self" }

        it { is_expected.to be true }
      end

      context "when the funding answer is not present" do
        let(:funding) { nil }

        xit("to be implemented in NPQ-3956") { is_expected.to be false } # rubocop:disable RSpec/PendingWithoutReason
      end

      context "when the course is EHCO" do
        let(:store) do
          minimum_answers
            .merge(funding_eligiblity_status_code: FundingEligibility::NOT_NEW_HEADTEACHER_REQUESTING_EHCO,
                   ehco_funding_choice:)
            .stringify_keys
        end

        context "when the ehco_funding_choice answer is present" do
          let(:ehco_funding_choice) { "self" }

          it { is_expected.to be true }
        end

        context "when the ehco_funding_choice answer is not present" do
          let(:ehco_funding_choice) { nil }

          xit("to be implemented in NPQ-3956") { is_expected.to be false } # rubocop:disable RSpec/PendingWithoutReason
        end
      end
    end

    context "when the application is subject to review" do
      let(:store) do
        minimum_answers
          .merge(funding_eligiblity_status_code: FundingEligibility::SUBJECT_TO_REVIEW,
                 funding:)
          .stringify_keys
      end

      context "when the funding answer is present" do
        let(:funding) { "self" }

        it { is_expected.to be true }
      end

      context "when the funding answer is not present" do
        let(:funding) { nil }

        it { is_expected.to be true }
      end
    end
  end

  describe "#previous_step" do
    subject { described_class.new(wizard:).previous_step }

    it { is_expected.to be(:share_provider) }
  end

  describe "#next_step" do
    subject { described_class.new(wizard:).next_step }

    it { is_expected.to be_nil }
  end

  describe "#last_step?" do
    subject { described_class.new(wizard:).last_step? }

    it { is_expected.to be true }
  end

  describe "#show_previously_funded_alert?" do
    subject { instance.show_previously_funded_alert? }

    context "when the pre-login funding eligibility status is funded" do
      before { store["pre_login_funding_eligiblity_status_code"] = FundingEligibility::FUNDED_ELIGIBILITY_RESULT }

      context "when the current funding eligibility status is previously_funded" do
        let(:calculated_funding_eligiblity_status_code) { FundingEligibility::PREVIOUSLY_FUNDED }

        it { is_expected.to be true }
      end

      context "when the current funding eligibility status is not previously_funded" do
        let(:calculated_funding_eligiblity_status_code) { FundingEligibility::FUNDED_ELIGIBILITY_RESULT }

        it { is_expected.to be false }
      end
    end

    context "when the pre-login funding eligibility status is not funded" do
      before { store["pre_login_funding_eligiblity_status_code"] = FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE }

      it { is_expected.to be false }
    end
  end

  describe "#before_render" do
    subject { instance.before_render }

    let(:store) { { funding_eligiblity_status_code: FundingEligibility::FUNDED_ELIGIBILITY_RESULT }.stringify_keys }

    context "when the user is previously funded" do
      let(:calculated_funding_eligiblity_status_code) { FundingEligibility::PREVIOUSLY_FUNDED }

      it "sets previously_funded in the store" do
        expect { subject }.to change { wizard.store["previously_funded"] }.from(nil).to(true)
      end

      it "updates the funding_eligibility_status_code in the store" do
        expect { subject }.to change { wizard.store["funding_eligiblity_status_code"] }.from(FundingEligibility::FUNDED_ELIGIBILITY_RESULT).to(FundingEligibility::PREVIOUSLY_FUNDED)
      end
    end

    context "when the user is not previously funded" do
      let(:calculated_funding_eligiblity_status_code) { FundingEligibility::FUNDED_ELIGIBILITY_RESULT }

      it "does not set previously_funded in the store" do
        expect { subject }.not_to(change { wizard.store["previously_funded"] })
      end

      it "does not update the funding_eligibility_status_code in the store" do
        expect { subject }.not_to(change { wizard.store["show_previously_funded_alert"] })
      end
    end
  end

  describe "#after_save" do
    subject(:after_save) { described_class.new(wizard:).after_save }

    let(:handle_submission_for_store) { instance_double(HandleSubmissionForStore, call: true) }

    before do
      allow(HandleSubmissionForStore).to receive(:new).with(store: wizard.store).and_return(handle_submission_for_store)
      allow(EmailTemplate).to receive(:call).with(data: wizard.store).and_return(:some_email_template)
    end

    it "sets the email template and submitted flag in the wizard store" do
      expect { subject }.to change { wizard.store["email_template"] }.from(nil).to(:some_email_template)
    end

    it "sets the submitted flag to true in the wizard store" do
      expect { subject }.to change { wizard.store["submitted"] }.from(nil).to(true)
    end

    it "sets the clear_tra_login flag to true in the wizard session" do
      expect { subject }.to change { wizard.session["clear_tra_login"] }.from(nil).to(true)
    end

    it "calls HandleSubmissionForStore" do
      expect(handle_submission_for_store).to receive(:call)

      subject
    end
  end
end
