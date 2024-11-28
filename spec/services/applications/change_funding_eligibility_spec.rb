# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeFundingEligibility, type: :model do
  subject(:service) { described_class.new(application:) }

  let(:application) { create(:application, :accepted) }

  describe "#change_funding_eligibility" do
    before { service.eligible_for_funding = true }

    context "with valid update" do
      it "returns true" do
        expect(service.change_funding_eligibility).to be true
      end

      it "changes eligibility_for_funding" do
        expect { service.change_funding_eligibility }
          .to change { application.reload.eligible_for_funding }.from(false).to(true)
      end
    end

    context "with invalid update" do
      let(:application) { nil }

      it "returns false" do
        expect(service.change_funding_eligibility).to be false
      end

      it "sets errors" do
        service.change_funding_eligibility

        expect(service.errors.messages[:application]).to include(/blank/)
      end
    end
  end
end
