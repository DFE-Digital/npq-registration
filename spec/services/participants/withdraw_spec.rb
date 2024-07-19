# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Withdraw, type: :model do
  it_behaves_like "a participant action" do
    let(:reason) { described_class::WITHDRAWAL_REASONS.sample }
    let(:instance) { described_class.new(lead_provider:, participant:, course_identifier:, reason:) }
  end

  it_behaves_like "a participant state transition", :withdraw, %w[active], "withdrawn" do
    let(:reason) { described_class::WITHDRAWAL_REASONS.sample }
    let(:instance) { described_class.new(lead_provider:, participant:, course_identifier:, reason:) }

    describe "validations" do
      it { is_expected.to validate_inclusion_of(:reason).in_array(described_class::WITHDRAWAL_REASONS).with_message("The property '#/reason' must be a valid reason") }

      context "when the application is already withdrawn" do
        let(:application) { create(:application, :accepted, :withdrawn) }

        it { expect(instance).to have_error(:participant, :already_withdrawn, "The participant is already withdrawn") }
      end

      context "when the application has no declarations" do
        let(:application) { create(:application, :accepted) }

        it { expect(instance).to have_error(:participant, :no_started_declarations, "An NPQ participant who has not got a started declaration cannot be withdrawn. Please contact support for assistance") }
      end

      context "when the application has no started declarations" do
        let(:application) { create(:application, :accepted) }

        before { create(:declaration, application:, declaration_type: "retained-1") }

        it { expect(instance).to have_error(:participant, :no_started_declarations, "An NPQ participant who has not got a started declaration cannot be withdrawn. Please contact support for assistance") }
      end
    end
  end
end
