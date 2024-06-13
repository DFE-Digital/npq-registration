# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Defer, type: :model do
  let(:lead_provider) { application.lead_provider }
  let(:participant) { application.user }
  let(:application) { create(:application, :accepted, :with_declaration) }
  let(:course_identifier) { application.course.identifier }
  let(:reason) { described_class::DEFERRAL_REASONS.sample }
  let!(:instance) { described_class.new(lead_provider:, participant:, course_identifier:, reason:) }

  it { expect(instance).to be_valid }

  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:participant) }
    it { is_expected.to validate_inclusion_of(:course_identifier).in_array(Course::IDENTIFIERS) }
    it { is_expected.to validate_inclusion_of(:reason).in_array(described_class::DEFERRAL_REASONS) }

    context "when the application is already deferred" do
      let(:application) { create(:application, :accepted, :deferred, :with_declaration) }

      it "adds an error to the participant attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :participant, type: :already_deferred)
      end
    end

    context "when the application is withdrawn" do
      let(:application) { create(:application, :accepted, :withdrawn, :with_declaration) }

      it "adds an error to the participant attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :participant, type: :withdrawn)
      end
    end

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
      let(:application) { create(:application, :with_declaration) }

      it "adds an error to the participant attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :participant, type: :blank)
      end
    end

    context "when the participant has no declarations" do
      let(:application) { create(:application, :accepted) }

      it "adds an error to the participant attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :participant, type: :no_declarations)
      end
    end
  end

  describe "#defer" do
    subject(:resume) { instance.defer }

    it { is_expected.to be(true) }

    it "creates a deferred application state" do
      expect { resume }.to change(ApplicationState, :count).by(1)

      expect(application.application_states.last).to have_attributes(
        lead_provider:,
        application:,
        state: "deferred",
        reason:,
      )
    end

    it "updates the application training status to deferred" do
      expect { resume }.to change { application.reload.training_status }.from("active").to("deferred")
    end

    context "when the instance is invalid" do
      let(:lead_provider) { nil }

      it "returns false and sets errors" do
        expect(resume).to be(false)
        expect(instance.errors).to be_present
      end
    end
  end
end
