# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeFundingEligibility, type: :model do
  subject(:service) { described_class.new(application:) }

  let(:application) { create(:application, :accepted) }

  before { allow(ApplicationFundingEligibilityMailer).to receive(:eligible_for_funding_mail).and_call_original }

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

      it { is_expected.to include(/billable or submitted declaration exists/i) }
    end

    context "with application with submitted declarations" do
      subject { service.tap(&:valid?).errors.full_messages }

      let(:service) { described_class.new(application:, eligible_for_funding: false) }

      let :application do
        create(:application, :accepted, eligible_for_funding: false).tap do |application|
          create(:declaration, :submitted, application:)
        end
      end

      it { is_expected.to include(/billable or submitted declaration exists/i) }
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

    context "with valid update from false to true" do
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

      it "sends an email" do
        expect(ApplicationFundingEligibilityMailer).to receive(:eligible_for_funding_mail).with(
          to: application.user.email,
          full_name: application.user.full_name,
          provider_name: application.lead_provider.name,
          course_name: application.course.name,
          ecf_id: application.ecf_id,
        )
        make_change
      end
    end

    context "with valid update from true to false" do
      let(:application) { create(:application, :pending, :eligible_for_funding) }

      before { service.eligible_for_funding = false }

      it { is_expected.to be true }

      it "changes eligibility_for_funding" do
        expect { make_change }
          .to change { application.reload.eligible_for_funding }
                .from(true)
                .to(false)
      end

      it "sets funding_eligibility_status_code" do
        expect { make_change }
          .to change { application.reload.funding_eligiblity_status_code }
                .from(nil)
                .to("marked_ineligible_by_policy")
      end

      it "does not send an email" do
        expect(ApplicationFundingEligibilityMailer).not_to receive(:eligible_for_funding_mail)
        make_change
      end
    end

    context "with a valid update from true to true" do
      let(:application) { create(:application, :pending, :eligible_for_funding) }

      before { service.eligible_for_funding = true }

      it { is_expected.to be true }

      it "does not send an email" do
        expect(ApplicationFundingEligibilityMailer).not_to receive(:eligible_for_funding_mail)
        make_change
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
