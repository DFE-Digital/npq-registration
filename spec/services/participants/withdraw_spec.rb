# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Withdraw, type: :model do
  let(:lead_provider) { application.lead_provider }
  let(:participant) { application.user }
  let(:application) { create(:application, :with_declaration, :accepted) }
  let(:course_identifier) { application.course.identifier }
  let(:reason) { described_class::WITHDRAWL_REASONS.sample }
  let!(:instance) { described_class.new(lead_provider:, participant:, course_identifier:, reason:) }

  it { expect(instance).to be_valid }

  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:participant) }
    it { is_expected.to validate_inclusion_of(:course_identifier).in_array(Course::IDENTIFIERS) }
    it { is_expected.to validate_inclusion_of(:reason).in_array(described_class::WITHDRAWL_REASONS) }

    context "when the application is already withdrawn" do
      let(:application) { create(:application, :accepted, :with_declaration, :withdrawn) }

      it "adds an error to the participant attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :participant, type: :already_withdrawn)
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

    context "when there is a matching application, but it has no declarations" do
      let(:application) { create(:application, :accepted) }

      it "adds an error to the participant attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :participant, type: :no_started_declarations)
      end
    end

    context "when there is a matching application, but it has no started declarations" do
      let(:application) { create(:application, :accepted) }

      before { create(:declaration, application:, declaration_type: "retained-1") }

      it "adds an error to the participant attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :participant, type: :no_started_declarations)
      end
    end
  end

  describe "#withdraw" do
    subject(:resume) { instance.withdraw }

    it { is_expected.to be(true) }

    it "creates a withdrawn application state" do
      expect { resume }.to change(ApplicationState, :count).by(1)

      expect(application.application_states.last).to have_attributes(
        lead_provider:,
        application:,
        state: "withdrawn",
        reason:,
      )
    end

    it "updates the application training status to withdrawn" do
      expect { resume }.to change { application.reload.training_status }.from("active").to("withdrawn")
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
