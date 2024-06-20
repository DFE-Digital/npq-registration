# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Withdraw, type: :model do
  it_behaves_like "a participant action", :withdraw, %w[active], "withdrawn" do
    let(:reason) { described_class::WITHDRAWL_REASONS.sample }
    let(:instance) { described_class.new(lead_provider:, participant:, course_identifier:, reason:) }

    describe "validations" do
      it { is_expected.to validate_inclusion_of(:reason).in_array(described_class::WITHDRAWL_REASONS) }

      context "when the application is already withdrawn" do
        let(:application) { create(:application, :accepted, :withdrawn) }

        it "adds an error to the participant attribute" do
          expect(instance).to be_invalid
          expect(instance.errors.first).to have_attributes(attribute: :participant, type: :already_withdrawn)
        end
      end

      context "when the application has no declarations" do
        let(:application) { create(:application, :accepted) }

        it "adds an error to the participant attribute" do
          expect(instance).to be_invalid
          expect(instance.errors.first).to have_attributes(attribute: :participant, type: :no_started_declarations)
        end
      end

      context "when the application has no started declarations" do
        let(:application) { create(:application, :accepted) }

        before { create(:declaration, application:, declaration_type: "retained-1") }

        it "adds an error to the participant attribute" do
          expect(instance).to be_invalid
          expect(instance.errors.first).to have_attributes(attribute: :participant, type: :no_started_declarations)
        end
      end
    end
  end
end
