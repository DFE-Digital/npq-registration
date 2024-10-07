require "rails_helper"

RSpec.describe Application do
  subject { create(:application) }

  describe "relationships" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:course) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:school).optional }
    it { is_expected.to belong_to(:private_childcare_provider).optional }
    it { is_expected.to belong_to(:itt_provider).optional }
    it { is_expected.to belong_to(:cohort).optional }
    it { is_expected.to belong_to(:schedule).optional }
    it { is_expected.to have_many(:ecf_sync_request_logs).dependent(:destroy) }
    it { is_expected.to have_many(:participant_id_changes).through(:user) }
    it { is_expected.to have_many(:application_states) }
    it { is_expected.to have_many(:declarations) }
  end

  describe "validations" do
    context "when the schedule cohort does not match the application cohort" do
      subject do
        build(:application).tap do |application|
          application.schedule = build(:schedule, cohort: build(:cohort, start_year: application.cohort.start_year + 1))
        end
      end

      it { is_expected.to have_error(:schedule, :cohort_mismatch, "The schedule cohort must match the application cohort") }
    end

    context "when accepted" do
      let(:cohort) { create(:cohort, :current, :with_funding_cap) }

      context "when funding_cap" do
        subject { build(:application, :accepted, cohort:) }

        it "validates funded_place boolean" do
          subject.funded_place = nil

          expect(subject).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.", :npq_separation)
        end

        it "validates funded_place eligibility" do
          subject.funded_place = true
          subject.eligible_for_funding = false

          expect(subject).to have_error(:funded_place, :not_eligible, "The participant is not eligible for funding, so '#/funded_place' cannot be set to true.", :npq_separation)
        end
      end

      context "when changing to wrong schedule" do
        let(:new_schedule) { create(:schedule, cohort:) }

        subject { create(:application, :accepted, cohort:) }

        it "returns validation error" do
          subject.schedule = new_schedule

          expect(subject).to have_error(:schedule, :invalid_for_course, "Selected schedule is not valid for the course", :npq_separation)
        end
      end
    end

    context "when ecf_api_disabled flag is toggled on" do
      before { Flipper.enable(Feature::ECF_API_DISABLED) }

      it { is_expected.to validate_presence_of(:ecf_id).with_message("Enter an ECF ID") }
      it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique") }

      it "ensures ecf_id is populated" do
        application = build(:application, ecf_id: nil)
        application.valid?
        expect(application.ecf_id).not_to be_nil
      end
    end

    context "when ecf_api_disabled flag is toggled off" do
      before { Flipper.disable(Feature::ECF_API_DISABLED) }

      it { is_expected.not_to validate_presence_of(:ecf_id) }
      it { is_expected.not_to validate_uniqueness_of(:ecf_id) }
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
  end

  describe "scopes" do
    describe ".unsynced" do
      it "returns records where ecf_id is null" do
        expect(described_class.unsynced.to_sql).to match(%("ecf_id" IS NULL))
      end
    end

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
        application.update!(lead_provider_approval_status: "accepted", participant_outcome_state: "passed")
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
    let(:application) { create(:application, :previously_funded, user:, course: Course.ehco) }
    let(:previous_application) { user.applications.where.not(id: application.id).first! }

    subject { application }

    context "when the application has been previously funded" do
      it { is_expected.to be_previously_funded }

      context "when funded place is `nil`" do
        before { previous_application.update!(funded_place: nil) }

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
      before { previous_application.update!(eligible_for_funding: false) }

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
end
