# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeFundingEligibility, type: :model do
  subject(:service) { described_class.new(application:) }

  let(:application) { create(:application, :accepted) }

  describe "validations" do
    it { is_expected.to validate_presence_of :application }

    context "with application with billable declarations" do
      subject { service.tap(&:valid?).errors.full_messages }

      let(:service) { described_class.new(application:, eligible_for_funding: false) }

      let :application do
        create(:application, :accepted, eligible_for_funding: false).tap do |application|
          create(:declaration, :eligible, application:)
        end
      end

      it { is_expected.to include(/billable declaration exists/i) }
    end

    context "with application with funded place" do
      subject { service.tap(&:valid?).errors.full_messages }

      let(:service) { described_class.new(application:, eligible_for_funding: false) }

      let :application do
        create(:application, :accepted, funded_place: true, eligible_for_funding: true)
      end

      it { is_expected.to include(/application is funded/i) }
    end
  end

  describe "#change_funding_eligibility" do
    subject(:make_change) { service.change_funding_eligibility }

    before { service.eligible_for_funding = true }

    context "with valid update" do
      it { is_expected.to be true }

      it "changes eligibility_for_funding" do
        expect { make_change }
          .to change { application.reload.eligible_for_funding }
                .from(false)
                .to(true)
      end

      it "sets funding_eligibility_status_code" do
        expect { make_change }
          .to change { application.reload.funding_eligiblity_status_code }
                .from(nil)
                .to("marked_funded_by_policy")
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
