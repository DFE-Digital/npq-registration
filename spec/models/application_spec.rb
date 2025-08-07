require "rails_helper"

RSpec.describe Application do
  subject(:application) { create(:application) }

  describe "relationships" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:course) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:school).optional }
    it { is_expected.to belong_to(:private_childcare_provider).optional }
    it { is_expected.to belong_to(:private_childcare_provider_including_disabled).optional.class_name("PrivateChildcareProvider").with_foreign_key(:private_childcare_provider_id) }
    it { is_expected.to belong_to(:itt_provider).optional }
    it { is_expected.to belong_to(:itt_provider_including_disabled).optional.class_name("IttProvider").with_foreign_key(:itt_provider_id) }
    it { is_expected.to belong_to(:cohort).optional }
    it { is_expected.to belong_to(:schedule).optional }
    it { is_expected.to have_many(:participant_id_changes).through(:user) }
    it { is_expected.to have_many(:application_states) }
    it { is_expected.to have_many(:declarations) }

    context "when the providers are disabled" do
      let(:private_childcare_provider) { create(:private_childcare_provider, :disabled) }
      let(:itt_provider) { create(:itt_provider, :disabled) }
      let(:application) { create(:application, private_childcare_provider:, itt_provider:).reload }

      it { expect(application.itt_provider).to be_nil }
      it { expect(application.private_childcare_provider).to be_nil }

      it { expect(application.itt_provider_including_disabled).to eq(itt_provider) }
      it { expect(application.private_childcare_provider_including_disabled).to eq(private_childcare_provider) }
    end
  end

  describe "paper_trail" do
    subject { create(:application, lead_provider_approval_status: "pending") }

    it "enables paper trail" do
      expect(subject).to be_versioned
    end

    it "creates a version with a note" do
      with_versioning do
        expect(PaperTrail).to be_enabled

        subject.update!(
          lead_provider_approval_status: "rejected",
          version_note: "This is a test",
        )
        version = subject.versions.last
        expect(version.note).to eq("This is a test")
        expect(version.object_changes["lead_provider_approval_status"]).to eq(%w[pending rejected])
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique") }

    context "when the schedule cohort does not match the application cohort" do
      subject do
        build(:application).tap do |application|
          application.schedule = build(:schedule, cohort: build(:cohort, start_year: application.cohort.start_year + 1))
        end
      end

      it { is_expected.to have_error(:schedule, :cohort_mismatch, "The schedule cohort must match the application cohort") }
    end

    context "when the cohort has a funding cap" do
      let(:cohort) { create(:cohort, :current, :with_funding_cap) }

      context "when accepted" do
        subject { build(:application, :accepted, cohort:) }

        it "validates funded_place is boolean" do
          subject.funded_place = nil

          expect(subject).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
        end

        it "validates funded_place eligibility" do
          subject.funded_place = true
          subject.eligible_for_funding = false

          expect(subject).to have_error(:funded_place, :not_eligible, "The participant is not eligible for funding, so '#/funded_place' cannot be set to true.")
        end
      end

      context "when changing to wrong schedule" do
        let(:new_schedule) { create(:schedule, cohort:) }

        subject { create(:application, :accepted, cohort:) }

        it "returns validation error" do
          subject.schedule = new_schedule

          expect(subject).to have_error(:schedule, :invalid_for_course, "The selected schedule is not valid for the course")
        end
      end
    end

    context "when the cohort does not have a funding cap" do
      let(:cohort) { create(:cohort, :without_funding_cap) }

      subject { build(:application, :accepted, cohort:) }

      it "validates funded_place is nil" do
        subject.funded_place = false

        expect(subject).to have_error(:funded_place, :should_not_be_set, "The '#//funded_place' field should not be set for cohorts that do not have a funding cap.")
      end
    end
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:kind_of_nursery).with_values(
        local_authority_maintained_nursery: "local_authority_maintained_nursery",
        preschool_class_as_part_of_school: "preschool_class_as_part_of_school",
        private_nursery: "private_nursery",
        another_early_years_setting: "another_early_years_setting",
        childminder: "childminder",
      ).backed_by_column_of_type(:enum).with_suffix
    }

    it {
      expect(subject).to define_enum_for(:headteacher_status).with_values(
        no: "no",
        yes_when_course_starts: "yes_when_course_starts",
        yes_in_first_two_years: "yes_in_first_two_years",
        yes_over_two_years: "yes_over_two_years",
        yes_in_first_five_years: "yes_in_first_five_years",
        yes_over_five_years: "yes_over_five_years",
      ).backed_by_column_of_type(:enum).with_suffix
    }

    it {
      expect(subject).to define_enum_for(:funding_choice).with_values(
        school: "school",
        trust: "trust",
        self: "self",
        another: "another",
        employer: "employer",
      ).backed_by_column_of_type(:enum).with_suffix
    }

    it {
      expect(subject).to define_enum_for(:lead_provider_approval_status).with_values(
        pending: "pending",
        accepted: "accepted",
        rejected: "rejected",
      ).backed_by_column_of_type(:enum).with_suffix
    }

    it {
      expect(subject).to define_enum_for(:training_status).with_values(
        active: "active",
        deferred: "deferred",
        withdrawn: "withdrawn",
      ).backed_by_column_of_type(:enum).with_suffix
    }

    it "defines an enum for review_status" do
      expect(subject).to define_enum_for(:review_status).with_values(
        "Needs review" => "needs_review",
        "Awaiting information" => "awaiting_information",
        "Re-register" => "reregister",
        "Decision made" => "decision_made",
      ).backed_by_column_of_type(:enum).with_suffix
    end
  end

  describe "scopes" do
    describe ".accepted" do
      it "returns accepted applications" do
        accepted_application = create(:application, :accepted)
        create(:application)

        expect(described_class.accepted).to contain_exactly(accepted_application)
      end
    end

    describe ".eligible_for_funding" do
      it "returns applications that are eligible for funding" do
        application_eligible_for_funding = create(:application, :eligible_for_funding)
        create(:application, eligible_for_funding: false)

        expect(described_class.eligible_for_funding).to contain_exactly(application_eligible_for_funding)
      end
    end

    describe ".with_targeted_delivery_funding_eligibility" do
      it "returns applications with targeted delivery funding eligibility" do
        application_with_targeted_delivery_funding_eligibility = create(:application, targeted_delivery_funding_eligibility: true)
        create(:application, targeted_delivery_funding_eligibility: false)

        expect(described_class.with_targeted_delivery_funding_eligibility).to contain_exactly(application_with_targeted_delivery_funding_eligibility)
      end
    end

    describe ".for_manual_review" do
      subject { described_class.for_manual_review.to_a }

      before { application }

      let(:application) { create(:application, review_status:) }
      let(:review_status) { nil }

      it { is_expected.not_to include(application) }

      Application.review_statuses.each_value do |enum_value|
        context "with review_status of #{enum_value}" do
          let(:review_status) { enum_value }

          it { is_expected.to include(application) }
        end
      end
    end
  end

  describe "#inside_catchment?" do
    it { expect(build(:application, teacher_catchment: "england")).to be_inside_catchment }
    it { expect(build(:application, teacher_catchment: "scotland")).not_to be_inside_catchment }
  end

  describe "#inside_uk_catchment?" do
    it { expect(build(:application, teacher_catchment: "england")).to be_inside_uk_catchment }
    it { expect(build(:application, teacher_catchment: "scotland")).to be_inside_uk_catchment }
    it { expect(build(:application, teacher_catchment: "wales")).to be_inside_uk_catchment }
    it { expect(build(:application, teacher_catchment: "northern_ireland")).to be_inside_uk_catchment }
    it { expect(build(:application, teacher_catchment: "jersey_guernsey_isle_of_man")).to be_inside_uk_catchment }
    it { expect(build(:application, teacher_catchment: "other")).not_to be_inside_uk_catchment }
  end

  describe "#employer_name" do
    shared_examples "employer_name" do
      it "displays proper employer_name" do
        expect(application.employer_name_to_display).to eq(name)
      end
    end

    context "when the application has school attached" do
      let(:school) { create(:school) }
      let(:name) { school.name }
      let(:application) { build(:application, school:) }

      include_examples "employer_name"
    end

    context "when the application has private school urn" do
      let(:private_childcare_provider) { create(:private_childcare_provider) }
      let(:name) { private_childcare_provider.provider_name }
      let(:application) { build(:application, private_childcare_provider:) }

      include_examples "employer_name"
    end

    context "when application has employer_name" do
      let(:name) { "Employer Foo Bar" }
      let(:application) { build(:application, school: nil, school_id: nil, employer_name: name) }

      include_examples "employer_name"
    end

    context "when no information about employer_name is available" do
      let(:application) do
        let(:name) { "" }
        let(:application) { build(:application, school: nil, school_id: nil, employer_name: nil) }

        include_examples "employer_name"
      end
    end
  end

  describe "versioning", :versioning do
    context "when changing versioned fields" do
      let(:application) { create(:application, lead_provider_approval_status: "pending", participant_outcome_state: nil) }

      before do
        application.update!(lead_provider_approval_status: "accepted", participant_outcome_state: "passed", funded_place: false)
      end

      it "has history of changes" do
        previous_application = application.versions.last.reify
        expect(application.lead_provider_approval_status).to eq("accepted")
        expect(application.participant_outcome_state).to eq("passed")

        expect(previous_application.lead_provider_approval_status).to eq("pending")
        expect(previous_application.participant_outcome_state).to be_nil
      end
    end
  end

  describe "#eligible_for_dfe_funding?" do
    let(:user) { create(:user) }

    subject { application }

    context "when application has been previously funded" do
      let(:application) { create(:application, :previously_funded, user:, course: Course.ehco) }

      it { is_expected.not_to be_eligible_for_dfe_funding }
    end

    context "when application has not been previously funded" do
      let(:application) { create(:application, user:, course: Course.ehco) }

      it "is not eligible for DfE funding if not eligible for funding" do
        application.update!(eligible_for_funding: false)

        expect(application).not_to be_eligible_for_dfe_funding
      end

      it "is eligible for DfE funding if the application is eligible for funding" do
        application.update!(eligible_for_funding: true)

        expect(application).to be_eligible_for_dfe_funding
      end
    end
  end

  describe "#previously_funded?" do
    let(:user) { create(:user) }
    let(:application) { create(:application, :previously_funded, user:, course: Course.ehco, cohort: cohort_with_funding_cap) }
    let(:cohort_with_funding_cap) { create(:cohort, :with_funding_cap) }
    let(:cohort_without_funding_cap) { create(:cohort, :without_funding_cap) }
    let(:previous_application) { user.applications.where.not(id: application.id).first! }

    subject { application }

    context "when the application has been previously funded" do
      it { is_expected.to be_previously_funded }

      context "when funded place is `nil`" do
        before do
          previous_application.update!(
            cohort: cohort_without_funding_cap,
            funded_place: nil,
            schedule: Schedule.find_by(cohort: cohort_without_funding_cap, course_group: previous_application.course.course_group),
          )
        end

        it { is_expected.to be_previously_funded }
      end

      context "when funded place is `false`" do
        before { previous_application.update!(funded_place: false) }

        it { is_expected.not_to be_previously_funded }
      end

      context "when funded place is `true`" do
        before { previous_application.update!(funded_place: true) }

        it { is_expected.to be_previously_funded }
      end
    end

    context "when the application has not been previously funded (previous application not accepted)" do
      before { previous_application.update!(lead_provider_approval_status: "rejected") }

      it { is_expected.not_to be_previously_funded }
    end

    context "when the application has not been previously funded (previous application is not for a rebranded alternative course)" do
      before do
        previous_application.schedule.course_group.courses << Course.npqeyl
        previous_application.update!(course: Course.npqeyl)
      end

      it { is_expected.not_to be_previously_funded }
    end

    context "when the application has not been previously funded (previous application is not eligible for funding)" do
      before { previous_application.update!(eligible_for_funding: false, funded_place: false) }

      it { is_expected.not_to be_previously_funded }
    end

    context "when transient_previously_funded is declared on the model" do
      subject { create(:application, eligible_for_funding: false) }

      before do
        def subject.transient_previously_funded
          false
        end
      end

      it "does not make a query to determine the previously_funded status" do
        expect(Application).not_to receive(:connection)
        expect(subject).not_to be_previously_funded
      end

      context "when transient_previously_funded is true" do
        before do
          def subject.transient_previously_funded
            true
          end
        end

        it "does not make a query to determine the previously_funded status" do
          expect(Application).not_to receive(:connection)
          expect(subject).to be_previously_funded
        end
      end
    end
  end

  describe "#ineligible_for_funding_reason" do
    subject { application.ineligible_for_funding_reason }

    context "when not previously funded or eligible_for_funding" do
      let(:application) { create(:application) }

      it { is_expected.to eq("establishment-ineligible") }
    end

    context "when not previously funded and eligible_for_funding" do
      let(:application) { create(:application, :eligible_for_funding) }

      it { is_expected.to be_nil }
    end

    context "when previously funded" do
      let(:application) { create(:application, :previously_funded) }

      it { is_expected.to eq("previously-funded") }
    end

    context "when transient_previously_funded is declared on the model" do
      subject { create(:application, eligible_for_funding: false) }

      before do
        def subject.transient_previously_funded
          false
        end
      end

      it "does not make a query to determine the previously_funded status" do
        expect(Application).not_to receive(:connection)
        expect(subject.ineligible_for_funding_reason).to eq("establishment-ineligible")
      end

      context "when transient_previously_funded is true" do
        before do
          def subject.transient_previously_funded
            true
          end
        end

        it "does not make a query to determine the previously_funded status" do
          expect(Application).not_to receive(:connection)
          expect(subject.ineligible_for_funding_reason).to eq("previously-funded")
        end
      end
    end
  end

  describe "#fundable?" do
    context "when it is eligible_for_funding" do
      subject { create(:application, eligible_for_funding: true, funded_place: nil) }

      it { is_expected.to be_fundable }
    end

    context "when it is not eligible_for_funding" do
      subject { create(:application, eligible_for_funding: false, funded_place: nil) }

      it { is_expected.not_to be_fundable }
    end

    context "when it is eligible_for_funding but has no funded place" do
      subject { create(:application, eligible_for_funding: true, funded_place: false) }

      it { is_expected.not_to be_fundable }
    end

    context "when it is eligible_for_funding but and has a funded place" do
      subject { create(:application, eligible_for_funding: true, funded_place: true) }

      it { is_expected.to be_fundable }
    end

    context "when it is not eligible_for_funding but and has a funded false" do
      subject { create(:application, eligible_for_funding: false, funded_place: false) }

      it { is_expected.not_to be_fundable }
    end

    context "when it was previously funded" do
      let(:user) { create(:user) }

      subject(:application) { create(:application, :eligible_for_funding, :previously_funded, user:, course: Course.ehco) }

      it { is_expected.not_to be_fundable }

      context "when is marked eligible by policy" do
        before { application.update!(funding_eligiblity_status_code: :marked_funded_by_policy) }

        it { is_expected.to be_fundable }
      end
    end
  end

  describe "touch user when application changes" do
    let!(:old_datetime) { 6.months.ago }
    let(:user) { create(:user, updated_at: old_datetime) }
    let(:application) { create(:application, :pending, user:) }

    context "when application is created" do
      it "updates user.updated_at" do
        freeze_time do
          expect(user.updated_at).to be_within(1.second).of(old_datetime)

          create(:application, user:)
          expect(user.updated_at).to eq(Time.zone.now)
        end
      end
    end

    context "when application is updated" do
      before do
        travel_to(old_datetime) do
          user
          application
        end
      end

      context "when lead_provider_approval_status is changed" do
        it "updates user.updated_at" do
          freeze_time do
            expect(user.updated_at).to be_within(1.second).of(old_datetime)
            expect(application.updated_at).to be_within(1.second).of(old_datetime)

            application.rejected_lead_provider_approval_status!

            expect(application.updated_at).to eq(Time.zone.now)
            expect(user.updated_at).to eq(Time.zone.now)
          end
        end

        context "when skip_touch_user_if_changed is true" do
          it "does not update user.updated_at" do
            freeze_time do
              expect(user.updated_at).to be_within(1.second).of(old_datetime)
              expect(application.updated_at).to be_within(1.second).of(old_datetime)

              application.update!(lead_provider_approval_status: "rejected", skip_touch_user_if_changed: true)

              expect(application.updated_at).to eq(Time.zone.now)
              expect(user.updated_at).to be_within(1.second).of(old_datetime)
            end
          end
        end
      end

      context "when lead_provider_approval_status is not changed" do
        it "does not update user.updated_at" do
          freeze_time do
            expect(user.updated_at).to be_within(1.second).of(old_datetime)
            expect(application.updated_at).to be_within(1.second).of(old_datetime)

            application.update!(employer_name: "Test name")

            expect(application.updated_at).to eq(Time.zone.now)
            expect(user.updated_at).to be_within(1.second).of(old_datetime)
          end
        end
      end
    end
  end

  describe "#latest_participant_outcome_state" do
    subject { application.latest_participant_outcome_state }

    let(:application) { create(:application, :accepted, participant_outcome_state: "anything") }
    let(:declaration) { create(:declaration, :completed, application:) }
    let!(:participant_outcome) { create(:participant_outcome, declaration:) }

    it "returns the state from latest outcome" do
      expect(subject).to eq("passed")
    end

    context "when no completed declaration exists" do
      before { declaration.update!(application: create(:application)) }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when other type of declaration exists" do
      before { declaration.update!(declaration_type: "retained-1") }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when completed declaration is voided" do
      before do
        declaration.update!(state: "voided")
        participant_outcome.update!(state: "voided")
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#lookup_state_change_reason" do
    subject(:lookup_state_change_reason) { application.lookup_state_change_reason(changed_at: Time.zone.now, changed_status: "deferred") }

    before { freeze_time }

    let!(:application_state) { create(:application_state, :deferred, application:, created_at: application.created_at + 0.5, reason: "other") }

    it "returns the reason for the application state" do
      expect(lookup_state_change_reason).to eq(application_state.reason)
    end

    context "when there is more than one application state within the time range" do
      before do
        create(:application_state, :deferred, application:, created_at: application.created_at + 0.4, reason: "career-break")
      end

      it "returns the most recent application state within the time range" do
        expect(lookup_state_change_reason).to eq(application_state.reason)
      end
    end

    context "when no application state matches the criteria" do
      it "returns nil" do
        expect(application.lookup_state_change_reason(changed_at: Time.zone.now, changed_status: "active")).to be_nil
      end
    end
  end
end
