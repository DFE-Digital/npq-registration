# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Defer, type: :model do
  it_behaves_like "a participant action" do
    let(:reason) { described_class::DEFERRAL_REASONS.sample }
    let(:instance) { described_class.new(lead_provider:, participant:, course_identifier:, reason:) }
  end

  it_behaves_like "a participant state transition", :defer, %w[active], "deferred" do
    let(:reason) { described_class::DEFERRAL_REASONS.sample }
    let(:instance) { described_class.new(lead_provider:, participant:, course_identifier:, reason:) }

    describe "validations" do
      it { is_expected.to validate_inclusion_of(:reason).in_array(described_class::DEFERRAL_REASONS).with_message("The property '#/reason' must be a valid reason") }

      context "when the application is already deferred" do
        let(:application) { create(:application, :with_declaration, :deferred) }

        it { expect(instance).to have_error(:participant, :already_deferred, "The participant is already deferred") }
      end

      context "when the application is withdrawn" do
        let(:application) { create(:application, :with_declaration, :withdrawn) }

        it { expect(instance).to have_error(:participant, :already_withdrawn, "The participant is already withdrawn") }
      end

      context "when the application has no declarations" do
        let(:application) { create(:application, :accepted) }

        it { expect(instance).to have_error(:participant, :no_declarations, "You cannot defer an NPQ participant that has no declarations") }
      end
    end
  end
end
