require "rails_helper"

RSpec.describe ParticipantOutcomes::Create, type: :model do
  let(:date_format) { "%Y-%m-%d" }
  let(:participant_id) { completed_declaration.user.ecf_id }
  let(:lead_provider) { completed_declaration.lead_provider }
  let(:completion_date) { 1.week.ago.strftime(date_format) }
  let(:course_identifier) { described_class::PERMITTED_COURSES.sample }
  let(:course) { Course.find_by(identifier: course_identifier) }
  let(:state) { described_class::STATES.sample }
  let(:completed_declaration) { create(:declaration, :completed, :payable, course:) }
  let(:instance) { described_class.new(lead_provider:, participant_id:, completion_date:, state:, course_identifier:) }

  describe "validations" do
    it { expect(instance).to be_valid }
    it { is_expected.to validate_presence_of(:lead_provider).with_message("Your update cannot be made as the '#/lead_provider' is not recognised. Check lead provider details and try again.") }
    it { is_expected.to validate_presence_of(:participant_id).with_message("Your update cannot be made as the '#/participant_id' is not recognised. Check participant details and try again.") }
    it { is_expected.to validate_presence_of(:completion_date).with_message("The '#/completion_date' is missing from your request. Please include a completion_date value and try again.") }
    it { is_expected.to validate_presence_of(:course_identifier).with_message("Enter a '#/course_identifier' value for this participant.") }
    it { is_expected.to validate_presence_of(:state).with_message("The '#/state' is missing from your request. Please include a 'passed' or 'failed' value and try again.") }
    it { is_expected.to allow_values(1.day.ago.strftime(date_format)).for(:completion_date) }
    it { is_expected.not_to allow_values(1.day.ago.strftime("%d-%m-%Y")).for(:completion_date).with_message("The '#/completion_date' value must be in the following format: 'yyyy-mm-dd'") }
    it { is_expected.not_to allow_values(1.day.from_now.strftime(date_format)).for(:completion_date).with_message("The '#/completion_date' value cannot be a future date. Check the date and try again.") }
    it { is_expected.to validate_inclusion_of(:course_identifier).in_array(described_class::PERMITTED_COURSES).with_message("The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.") }
    it { is_expected.to validate_inclusion_of(:state).in_array(described_class::STATES).with_message("The attribute '#/state' can only include 'passed' or 'failed' values. If you need to void an outcome, you will need to void the associated 'completed' declaration.") }

    context "when the completion date is a valid format but invalid date" do
      let(:completion_date) { "2021-13-01" }

      it { is_expected.to have_error(:completion_date, :invalid, "The '#/completion_date' value must be in the following format: 'yyyy-mm-dd'") }
    end

    describe "completed declarations" do
      context "when the participant has no completed declarations" do
        before { completed_declaration.destroy! }

        it { is_expected.to have_error(:base, :no_completed_declarations, "The participant has not had a 'completed' declaration submitted for them. Therefore you cannot update their outcome.") }
      end

      context "when the participant has completed declarations on another lead provider" do
        let(:lead_provider) { LeadProvider.where.not(id: lead_provider.id).first }

        it { is_expected.to have_error(:base, :no_completed_declarations, "The participant has not had a 'completed' declaration submitted for them. Therefore you cannot update their outcome.") }
      end

      context "when the participant has completed declarations with a different course identifier" do
        let(:other_course) { Course.find_by(identifier: described_class::PERMITTED_COURSES.excluding(course_identifier).sample) }

        before { completed_declaration.application.update!(course: other_course) }

        it { is_expected.to have_error(:base, :no_completed_declarations, "The participant has not had a 'completed' declaration submitted for them. Therefore you cannot update their outcome.") }
      end

      Declaration.states.keys.excluding(Declaration::BILLABLE_STATES + Declaration::VOIDABLE_STATES).each do |state|
        context "when the participant has completed declarations for the same lead provider and course that are #{state}" do
          before { completed_declaration.update!(state:) }

          it { is_expected.to have_error(:base, :no_completed_declarations, "The participant has not had a 'completed' declaration submitted for them. Therefore you cannot update their outcome.") }
        end
      end
    end
  end

  describe "#create_outcome" do
    subject(:create_outcome) { instance.create_outcome }

    let(:created_outcome) { instance.created_outcome }

    context "when an existing participant outcome already exists" do
      context "when it matches the state and completion_date passed into the service" do
        let!(:existing_outcome) { create(:participant_outcome, state:, completion_date:, declaration: completed_declaration) }

        it { is_expected.to be(true) }
        it { expect { create_outcome }.not_to change(ParticipantOutcome, :count) }

        it "sets the created_outcome to the existing outcome" do
          create_outcome
          expect(created_outcome).to eq(existing_outcome)
        end
      end

      context "when it matches the state but not the completion_date passed into the service" do
        let!(:existing_outcome) { create(:participant_outcome, state:, completion_date: 1.month.ago, declaration: completed_declaration) }

        it { is_expected.to be(true) }
        it { expect { create_outcome }.to change(ParticipantOutcome, :count) }

        it "sets the created_outcome to the newly created outcome" do
          create_outcome
          expect(created_outcome).not_to eq(existing_outcome)
          expect(created_outcome).to have_attributes({
            declaration: completed_declaration,
            state:,
            completion_date: completion_date.to_date,
          })
        end
      end

      context "when it matches the completion_date but not the state passed into the service" do
        let(:other_state) { described_class::STATES.excluding(state).sample }
        let!(:existing_outcome) { create(:participant_outcome, state: other_state, completion_date:, declaration: completed_declaration) }

        it { is_expected.to be(true) }
        it { expect { create_outcome }.to change(ParticipantOutcome, :count) }

        it "sets the created_outcome to the newly created outcome" do
          create_outcome
          expect(created_outcome).not_to eq(existing_outcome)
          expect(created_outcome).to have_attributes({
            declaration: completed_declaration,
            state:,
            completion_date: completion_date.to_date,
          })
        end
      end

      context "when there are multiple existing participant outcomes that both match and do not match the state and completion_date passed into the service" do
        let!(:matching_outcome) { create(:participant_outcome, state:, completion_date:, declaration: completed_declaration) }
        let!(:not_matching_outcome) { create(:participant_outcome, completion_date: 1.month.ago, declaration: completed_declaration) }

        context "when the matching outcome is the latest" do
          before { matching_outcome.update!(created_at: not_matching_outcome.created_at + 1.day) }

          it { is_expected.to be(true) }
          it { expect { create_outcome }.not_to change(ParticipantOutcome, :count) }

          it "sets the created_outcome to the latest existing outcome" do
            create_outcome
            expect(created_outcome).to eq(matching_outcome)
          end
        end

        context "when the matching outcome is not the latest" do
          before { matching_outcome.update!(created_at: not_matching_outcome.created_at - 1.day) }

          it { is_expected.to be(true) }
          it { expect { create_outcome }.to change(ParticipantOutcome, :count) }

          it "sets the created_outcome to the newly created outcome" do
            create_outcome
            expect(created_outcome).not_to eq(matching_outcome)
            expect(created_outcome).to have_attributes({
              declaration: completed_declaration,
              state:,
              completion_date: completion_date.to_date,
            })
          end
        end
      end
    end

    context "when an existing participant outcome does not exist" do
      it { is_expected.to be(true) }

      it "creates a new participant outcome, assigning it to created_outcome" do
        expect { create_outcome }.to change(ParticipantOutcome, :count).by(1)

        expect(created_outcome).to have_attributes({
          declaration: completed_declaration,
          state:,
          completion_date: completion_date.to_date,
        })

        expect(created_outcome.ecf_id).to be_present
      end
    end

    context "when not valid" do
      let(:state) { "invalid" }

      it { is_expected.to be(false) }
      it { expect { create_outcome }.not_to change(ParticipantOutcome, :count) }
    end
  end
end
