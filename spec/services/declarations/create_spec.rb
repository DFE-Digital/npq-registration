# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::Create, type: :model do
  let(:lead_provider) { LeadProvider.all.sample }
  let(:cohort) { create(:cohort, :current) }
  let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
  let(:course) { create(:course, :senior_leadership, course_group:) }
  let!(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
  let(:application) { create(:application, :accepted, cohort:, course:, lead_provider:) }
  let(:participant) { application.user }
  let(:participant_id) { participant.ecf_id }
  let(:declaration_type) { "started" }
  let(:declaration_date) { schedule.applies_from + 1.day }
  let(:course_identifier) { course.identifier }
  let(:has_passed) { true }
  let(:params) do
    {
      lead_provider:,
      participant_id:,
      declaration_type:,
      declaration_date: declaration_date.rfc3339,
      course_identifier:,
      has_passed:,
    }
  end
  let!(:statement) { create(:statement, cohort:, lead_provider:) }

  subject(:service) { described_class.new(**params) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider).with_message("Your update cannot be made as the '#/lead_provider' is not recognised. Check lead provider details and try again.") }
    it { is_expected.to validate_presence_of(:participant_id).with_message("The property '#/participant_id' must be present") }
    it { is_expected.to validate_presence_of(:declaration_type).with_message("Enter a '#/declaration_type'.") }
    it { is_expected.to validate_presence_of(:declaration_date).with_message("Enter a '#/declaration_date'.") }

    context "when lead providers don't match" do
      before { params[:lead_provider] = create(:lead_provider) }

      it { expect(subject).to have_error(:participant_id, :invalid_participant, "Your update cannot be made as the '#/participant_id' is not recognised. Check participant details and try again.") }
    end

    context "when the course is invalid" do
      let(:course_identifier) { "invalid" }

      it { is_expected.to have_error(:course_identifier, :invalid, "The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.") }

      context "when there are other errors" do
        let(:participant_id) { "not-found" }

        it "omits the course_identifier error" do
          expect(subject).to have_error(:participant_id)
          expect(subject).not_to have_error(:course_identifier)
        end
      end
    end

    context "when the course is nil" do
      let(:course_identifier) { nil }

      it { expect(subject).to have_error(:course_identifier, :invalid, "The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.") }
    end

    context "when declaration date is invalid" do
      before { params[:declaration_date] = "2023-19-01T11:21:55Z" }

      it { is_expected.to have_error(:declaration_date, :invalid, "Enter a valid RCF3339 '#/declaration_date'.") }
    end

    context "when declaration time is invalid" do
      before { params[:declaration_date] = "2023-19-01T29:21:55Z" }

      it { is_expected.to have_error(:declaration_date, :invalid, "Enter a valid RCF3339 '#/declaration_date'.") }
    end

    context "when the declaration_date is in the future" do
      before { params[:declaration_date] = 1.day.from_now.rfc3339 }

      it { is_expected.to have_error(:declaration_date, :future_declaration_date, "The '#/declaration_date' value cannot be a future date. Check the date and try again.") }
    end

    context "when the declaration_date is today" do
      before { params[:declaration_date] = Time.zone.today.rfc3339 }

      it { is_expected.to be_valid }
    end

    context "when the declaration_date is in the past" do
      before { params[:declaration_date] = 1.day.ago.rfc3339 }

      it { is_expected.to be_valid }
    end

    context "when a participant has been withdrawn" do
      before do
        travel_to(withdrawal_time) do
          ApplicationState.create!(application:, lead_provider:, state: :withdrawn)
          application.withdrawn!
        end
      end

      context "when the declaration is made after the participant has been withdrawn" do
        let(:withdrawal_time) { declaration_date - 1.day }

        it { is_expected.to have_error(:participant_id, :declaration_must_be_before_withdrawal_date, "This participant withdrew from this course on #{application.application_states.last.created_at.rfc3339}. Enter a '#/declaration_date' that's on or before the withdrawal date.") }
      end
    end

    context "when an existing declaration already exists" do
      before { service.create_declaration }

      it { is_expected.to have_error(:base, :declaration_already_exists, "A declaration has already been submitted that will be, or has been, paid for this event") }

      context "when the state submitted" do
        it "does not create duplicates" do
          expect { service.create_declaration }.not_to change(Declaration, :count)
        end
      end

      context "with an fundable participant" do
        let(:application) { create(:application, :eligible_for_funded_place, cohort:, course:, lead_provider:) }
        let(:existing_declaration) { Declaration.last }

        %w[eligible payable paid].each do |state|
          context "when the state is #{state}" do
            before { existing_declaration.update!(state:) }

            it "does not create duplicates" do
              expect { service.create_declaration }.not_to change(Declaration, :count)

              expect(existing_declaration.state).to eq(state)
            end
          end
        end
      end
    end

    context "when submitting completed" do
      let(:declaration_type) { "completed" }

      context "when has_passed is nil" do
        let(:has_passed) { nil }

        it { is_expected.to have_error(:has_passed, :invalid, "Enter 'true' or 'false' in the '#/has_passed' field to indicate whether this participant has passed or failed their course.") }
      end

      context "when has_passed is invalid text" do
        let(:has_passed) { "no_supported" }

        it { is_expected.to have_error(:has_passed, :invalid, "Enter 'true' or 'false' in the '#/has_passed' field to indicate whether this participant has passed or failed their course.") }
      end

      context "when has_passed is true" do
        let(:has_passed) { true }

        it "creates a passed participant outcome" do
          expect {
            service.create_declaration
          }.to change(ParticipantOutcome, :count).by(1)

          declaration = Declaration.last
          outcome = declaration.participant_outcomes.first
          expect(outcome.completion_date).to eql(declaration.declaration_date.to_date)
          expect(outcome).to be_passed_state
        end
      end

      context "when has_passed is 'true'" do
        let(:has_passed) { "true" }

        it "creates a passed participant outcome" do
          expect {
            service.create_declaration
          }.to change(ParticipantOutcome, :count).by(1)

          declaration = Declaration.last
          outcome = declaration.participant_outcomes.first
          expect(outcome.completion_date).to eql(declaration.declaration_date.to_date)
          expect(outcome).to be_passed_state
        end
      end

      context "when has_passed is false" do
        let(:has_passed) { false }

        it "creates a failed participant outcome" do
          expect {
            service.create_declaration
          }.to change(ParticipantOutcome, :count).by(1)

          declaration = Declaration.last
          outcome = declaration.participant_outcomes.first
          expect(outcome.completion_date).to eql(declaration.declaration_date.to_date)
          expect(outcome).to be_failed_state
        end
      end

      context "when has_passed is 'false'" do
        let(:has_passed) { "false" }

        it "creates a failed participant outcome" do
          expect {
            service.create_declaration
          }.to change(ParticipantOutcome, :count).by(1)

          declaration = Declaration.last
          outcome = declaration.participant_outcomes.first
          expect(outcome.completion_date).to eql(declaration.declaration_date.to_date)
          expect(outcome).to be_failed_state
        end
      end

      context "when ehco course identifier" do
        let(:course_group) { CourseGroup.find_by(name: "ehco") || create(:course_group, name: "ehco") }
        let(:course) { create(:course, :early_headship_coaching_offer, course_group:) }

        it "does not create a participant outcome" do
          expect {
            service.create_declaration
          }.not_to change(ParticipantOutcome, :count)
        end
      end

      context "when aso course identifier" do
        let(:course_group) { CourseGroup.find_by(name: "support") || create(:course_group, name: "support") }
        let(:course) { create(:course, :additional_support_offer, course_group:) }

        it "does not create a participant outcome" do
          expect {
            service.create_declaration
          }.not_to change(ParticipantOutcome, :count)
        end
      end

      context "when ParticipantOutcomes::Create service class is invalid" do
        before do
          allow_any_instance_of(ParticipantOutcomes::Create).to receive(:valid?).and_return(false)
        end

        it "raises a ArgumentError exception" do
          expect(Declaration.completed_declaration_type.count).to be(0)
          expect { service.create_declaration }.to raise_error(ArgumentError).with_message(I18n.t(:cannot_create_completed_declaration))
          expect(Declaration.completed_declaration_type.count).to be(0)
        end
      end
    end

    context "when there are no available output fee statements" do
      before { lead_provider.next_output_fee_statement(cohort).update!(output_fee: false) }

      context "when the declarations is submitted" do
        it { is_expected.to be_valid }
      end

      context "when the declaration is eligible" do
        let(:application) { create(:application, :eligible_for_funded_place, cohort:, course:, lead_provider:) }

        it { is_expected.to have_error(:cohort, :no_output_fee_statement, "You cannot submit or void declarations for the #{cohort.start_year} cohort. The funding contract for this cohort has ended. Get in touch if you need to discuss this with us.") }
      end

      context "when there is an existing billable declaration" do
        before { create(:declaration, :paid, application:, declaration_date:) }

        it { is_expected.to have_error(:cohort, :no_output_fee_statement, "You cannot submit or void declarations for the #{cohort.start_year} cohort. The funding contract for this cohort has ended. Get in touch if you need to discuss this with us.") }
      end
    end
  end

  describe "#create_declaration" do
    subject { described_class.new(**params).create_declaration }

    it "creates a declaration" do
      expect { subject }.to change(Declaration, :count).by(1)
    end

    it "stores the correct data" do
      subject

      declaration = Declaration.last

      expect(declaration.declaration_type).to eq(declaration_type)
      expect(declaration.user.ecf_id).to eq(participant.ecf_id)
      expect(declaration.course_identifier).to eq(course_identifier)
      expect(declaration.lead_provider).to eq(lead_provider)
      expect(declaration.cohort).to eq(cohort)
    end

    context "when declaration is `submitted`" do
      let(:application) { create(:application, :eligible_for_funded_place, cohort:, course:, lead_provider:) }

      it "calls `StatementAttacher`" do
        expect_any_instance_of(Declarations::StatementAttacher).to receive(:attach)

        subject
      end
    end

    context "when declaration is not fundable" do
      before do
        application.update(eligible_for_funding: true, funded_place: false)
      end

      it "sets the declaration to submitted" do
        subject

        declaration = Declaration.last
        expect(declaration).to be_submitted_state
      end
    end

    context "when posting for next cohort" do
      let(:cohort) { create(:cohort, :next) }
      let(:application) { create(:application, :eligible_for_funded_place, cohort:, course:, lead_provider:) }
      let!(:statement) { create(:statement, cohort:, lead_provider:, deadline_date: declaration_date + 6.weeks) }

      it "creates declaration to next cohort statement" do
        travel_to declaration_date + 1.day do
          expect { subject }.to change(Declaration, :count).by(1)

          declaration = Declaration.last

          expect(declaration).to be_eligible_state
          expect(declaration.statements).to include(statement)
        end
      end
    end

    context "when duplicate declaration exists" do
      let(:original_user) { create(:user, trn: participant.trn) }
      let(:original_application) { create(:application, :accepted, cohort:, course:, user: original_user) }
      let!(:original_declaration) { create(:declaration, application: original_application) }

      it "creates an `ineligible` declaration superseded by the original declaration" do
        subject

        declaration = Declaration.last

        expect(declaration).to be_ineligible_state
        expect(declaration.superseded_by).to eq(original_declaration)
      end
    end
  end
end
