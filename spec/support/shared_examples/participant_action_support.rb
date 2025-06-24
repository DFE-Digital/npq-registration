# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a participant action" do
  let(:lead_provider) { application.lead_provider }
  let(:participant_id) { application.user.ecf_id }
  let(:application) { create(:application, :accepted, :with_declaration) }
  let(:course_identifier) { application.course.identifier }

  it { expect(instance).to be_valid }

  describe "validations" do
    subject { instance }

    it { is_expected.to validate_presence_of(:lead_provider).with_message("Your update cannot be made as the '#/lead_provider' is not recognised. Check lead provider details and try again.") }
    it { is_expected.to validate_presence_of(:participant_id).with_message("The property '#/participant_id' must be present") }
    it { is_expected.to validate_inclusion_of(:course_identifier).in_array(Course::IDENTIFIERS).with_message("The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.") }

    context "when a matching application does not exist (different course identifier)" do
      let(:course_identifier) { Course::IDENTIFIERS.excluding(application.course.identifier).sample }

      it { is_expected.to have_error_count(1) }
      it { is_expected.to have_error(:participant_id, :application_not_found, "Your update cannot be made as an accepted application cannot be found for the given '#/participant_id' and '#/course_identifier'.") }
    end

    context "when a matching application does not exist (different lead provider)" do
      let(:lead_provider) { create(:lead_provider, name: "Different to #{application.lead_provider.name}") }

      it { is_expected.to have_error(:participant_id, :invalid_participant, "Your update cannot be made as the '#/participant_id' is not recognised. Check participant details and try again.") }
    end

    context "when there is a matching application, but it is not accepted" do
      let(:application) { create(:application) }

      # This error is misleading, it should be :application_not_found really,
      # but to implement this is complex, because the current Participants::Query only returns users with accepted applications
      it { is_expected.to have_error(:participant_id, :invalid_participant, "Your update cannot be made as the '#/participant_id' is not recognised. Check participant details and try again.") }
    end

    context "when the participant does not exist" do
      let(:participant_id) { "non-existent-participant-id" }

      it { is_expected.to have_error_count(1) }
      it { is_expected.to have_error(:participant_id, :invalid_participant, "Your update cannot be made as the '#/participant_id' is not recognised. Check participant details and try again.") }
    end

    it_behaves_like "a model that validates participant_id currency"

    context "when a non-existent course identifier is provided" do
      let(:course_identifier) { "non-existent-course-identifier" }

      it { is_expected.to have_error_count(1) }
      it { is_expected.to have_error(:course_identifier, :inclusion, "The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.") }
    end
  end

  describe ".new_filtering_attributes" do
    context "when extra params are sent to the action service" do
      subject { described_class.new_filtering_attributes(lead_provider:, participant_id:, course_identifier:, reason: "test", schedule_identifier: "any") }

      it "does not raise any exception" do
        expect { subject }.not_to raise_error
      end
    end
  end
end

RSpec.shared_examples "a participant state transition" do |action, from_states, to_state|
  let(:lead_provider) { application.lead_provider }
  let(:participant_id) { application.user.ecf_id }
  let(:application) { create(:application, :accepted, :with_declaration, training_status: from_states.sample) }
  let(:course_identifier) { application.course.identifier }

  it { expect(instance).to be_valid }

  describe "##{action}" do
    subject(:perform_action) { instance.send(action) }

    it { is_expected.to be(true) }

    from_states.each do |from_state|
      context "when the application is #{from_state}" do
        let(:application) { create(:application, :accepted, :with_declaration, training_status: from_state) }

        it "creates a #{to_state} application state" do
          expect { perform_action }.to change(ApplicationState, :count).by(1)

          expected_attributes = {
            lead_provider:,
            application:,
            state: to_state,
          }

          expected_attributes[:reason] = reason if defined?(reason)

          expect(application.application_states.last).to have_attributes(expected_attributes)
        end

        it "updates the application training status to #{to_state}" do
          expect { perform_action }.to change { application.reload.training_status }.to(to_state)
        end
      end
    end

    context "when the instance is invalid" do
      let(:lead_provider) { nil }

      it "returns false and sets errors" do
        expect(perform_action).to be(false)
        expect(instance.errors).to be_present
      end
    end
  end
end
