# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Defer, type: :model do
  it_behaves_like "a participant action" do
    let(:reason) { described_class::DEFERRAL_REASONS.sample }
    let(:instance) { described_class.new(lead_provider:, participant_id:, course_identifier:, reason:) }
  end

  it_behaves_like "a participant state transition", :defer, %w[active], "deferred" do
    let(:reason) { described_class::DEFERRAL_REASONS.sample }
    let(:instance) { described_class.new(lead_provider:, participant_id:, course_identifier:, reason:) }

    describe "validations" do
      it { is_expected.to validate_inclusion_of(:reason).in_array(described_class::DEFERRAL_REASONS).with_message("The property '#/reason' must be a valid reason") }

      context "when the application is already deferred" do
        let(:application) { create(:application, :with_declaration, :deferred) }

        it { expect(instance).to have_error(:participant_id, :already_deferred, "The participant is already deferred") }
      end

      context "when the application is withdrawn" do
        let(:application) { create(:application, :with_declaration, :withdrawn) }

        it { expect(instance).to have_error(:participant_id, :already_withdrawn, "The participant is already withdrawn") }
      end

      context "when the application has no declarations" do
        let(:application) { create(:application, :accepted) }

        it { expect(instance).to have_error(:participant_id, :no_declarations, "You cannot defer an NPQ participant that has no declarations") }
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
        reason: described_class::DEFERRAL_REASONS.sample,
      )
    end

    it "does not send a deferred notification email" do
      expect(ApplicationDeferredMailer).not_to send_mail(:application_deferred_mail)
      instance.defer
    end

    # NPQ-3934: deferred notifications are turned off. Swap the examples below
    # when they are turned on again.
    #
    # it "sends a deferred notification email" do
    #   expect(ApplicationDeferredMailer).to send_mail(:application_deferred_mail)
    #     .with_params(to: application.user.email,
    #                  full_name: application.user.full_name,
    #                  provider_name: application.lead_provider.name,
    #                  course_name: application.course.name,
    #                  ecf_id: application.ecf_id)
    #   instance.defer
    # end
    #
    # context "when the participant has no email address" do
    #   before do
    #     application.user.update_columns(
    #       email: nil,
    #       archived_email: "archived@example.com",
    #       archived_at: Time.zone.now,
    #     )
    #   end
    #
    #   it "does not send a deferred notification email" do
    #     expect(ApplicationDeferredMailer).not_to send_mail(:application_deferred_mail)
    #     instance.defer
    #   end
    # end
    #
    # context "when the application has a completed declaration" do
    #   before { create(:declaration, application:, declaration_type: "completed") }
    #
    #   it "does not send a deferred notification email" do
    #     expect(ApplicationDeferredMailer).not_to send_mail(:application_deferred_mail)
    #     instance.defer
    #   end
    # end
  end
end
