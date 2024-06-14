# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a participant action" do |action, from_states, to_state|
  let(:lead_provider) { application.lead_provider }
  let(:participant) { application.user }
  let(:application) { create(:application, :accepted, :with_declaration, training_status: from_states.sample) }
  let(:course_identifier) { application.course.identifier }

  it { expect(instance).to be_valid }

  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:participant) }
    it { is_expected.to validate_inclusion_of(:course_identifier).in_array(Course::IDENTIFIERS) }

    context "when a matching application does not exist (different course identifier)" do
      let(:course_identifier) { Course::IDENTIFIERS.excluding(application.course.identifier).sample }

      it "adds an error to the participant attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :participant, type: :blank)
      end
    end

    context "when a matching application does not exist (different lead provider)" do
      let(:lead_provider) { create(:lead_provider) }

      it "adds an error to the participant attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :participant, type: :blank)
      end
    end

    context "when there is a matching application, but it is not accepted" do
      let(:application) { create(:application) }

      it "adds an error to the participant attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :participant, type: :blank)
      end
    end
  end

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
