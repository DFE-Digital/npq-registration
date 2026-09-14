# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Withdraw, type: :model do
  it_behaves_like "a participant action" do
    let(:reason) { described_class::WITHDRAWAL_REASONS.sample }
    let(:instance) { described_class.new(lead_provider:, participant_id:, course_identifier:, reason:) }
  end

  it_behaves_like "a participant state transition", :withdraw, %w[active], "withdrawn" do
    let(:reason) { described_class::WITHDRAWAL_REASONS.sample }
    let(:instance) { described_class.new(lead_provider:, participant_id:, course_identifier:, reason:) }

    describe "validations" do
      it { is_expected.to validate_inclusion_of(:reason).in_array(described_class::WITHDRAWAL_REASONS).with_message("The property '#/reason' must be a valid reason") }

      context "with new withdrawal reasons" do
        %w[
          assessment-requirements-not-met
          change-in-career
          disengaged-and-unresponsive
          non-payment-of-invoice
        ].each do |new_reason|
          it "accepts #{new_reason} as a valid withdrawal reason" do
            expect(described_class::WITHDRAWAL_REASONS).to include(new_reason)
          end
        end
      end

      context "when the application is already withdrawn" do
        let(:application) { create(:application, :accepted, :withdrawn) }

        it { expect(instance).to have_error(:participant_id, :already_withdrawn, "The participant is already withdrawn") }
      end

      context "when the application has no declarations" do
        let(:application) { create(:application, :accepted) }

        it { expect(instance).to have_error(:participant_id, :no_started_declarations, "An NPQ participant who has not got a started declaration cannot be withdrawn. Please contact support for assistance") }
      end

      context "when the application has no started declarations" do
        let(:application) { create(:application, :accepted) }

        before { create(:declaration, application:, declaration_type: "retained-1") }

        it { expect(instance).to have_error(:participant_id, :no_started_declarations, "An NPQ participant who has not got a started declaration cannot be withdrawn. Please contact support for assistance") }
      end
    end
  end

  describe "email notifications" do
    let(:application) { create(:application, :accepted, :with_declaration) }
    let(:instance) do
      described_class.new(
        lead_provider: application.lead_provider,
        participant_id: application.user.ecf_id,
        course_identifier: application.course.identifier,
        reason: described_class::WITHDRAWAL_REASONS.sample,
      )
    end

    it "sends a withdrawn notification email" do
      expect(ApplicationWithdrawnMailer).to send_mail(:application_withdrawn_mail)
        .with_params(to: application.user.email,
                     full_name: application.user.full_name,
                     provider_name: application.lead_provider.name,
                     course_name: application.course.name,
                     ecf_id: application.ecf_id)
      instance.withdraw
    end

    context "when the participant has no email address" do
      before do
        application.user.update_columns(
          email: nil,
          archived_email: "archived@example.com",
          archived_at: Time.zone.now,
        )
      end

      it "does not send a withdrawn notification email" do
        expect(ApplicationWithdrawnMailer).not_to send_mail(:application_withdrawn_mail)
        instance.withdraw
      end
    end

    context "when the application has a completed declaration" do
      before { create(:declaration, application:, declaration_type: "completed") }

      it "does not send a withdrawn notification email" do
        expect(ApplicationWithdrawnMailer).not_to send_mail(:application_withdrawn_mail)
        instance.withdraw
      end
    end
  end
end
