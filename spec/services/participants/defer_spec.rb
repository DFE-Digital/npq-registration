# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Defer, type: :model do
  it_behaves_like "a participant action", :defer, %w[active], "deferred" do
    let(:reason) { described_class::DEFERRAL_REASONS.sample }
    let(:instance) { described_class.new(lead_provider:, participant:, course_identifier:, reason:) }

    describe "validations" do
      it { is_expected.to validate_inclusion_of(:reason).in_array(described_class::DEFERRAL_REASONS) }

      context "when the application is already deferred" do
        let(:application) { create(:application, :with_declaration, :deferred) }

        it "adds an error to the participant attribute" do
          expect(instance).to be_invalid
          expect(instance.errors.first).to have_attributes(attribute: :participant, type: :already_deferred)
        end
      end

      context "when the application is withdrawn" do
        let(:application) { create(:application, :with_declaration, :withdrawn) }

        it "adds an error to the participant attribute" do
          expect(instance).to be_invalid
          expect(instance.errors.first).to have_attributes(attribute: :participant, type: :already_withdrawn)
        end
      end

      context "when the application has no declarations" do
        let(:application) { create(:application, :accepted) }

        it "adds an error to the participant attribute" do
          expect(instance).to be_invalid
          expect(instance.errors.first).to have_attributes(attribute: :participant, type: :no_declarations)
        end
      end
    end
  end
end
