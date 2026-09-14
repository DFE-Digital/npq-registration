# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::Resume, type: :model do
  it_behaves_like "a participant action" do
    let(:instance) { described_class.new(lead_provider:, participant_id:, course_identifier:) }
    let(:application) { create(:application, :accepted, :with_declaration, training_status: %w[withdrawn deferred].sample) }
  end

  it_behaves_like "a participant state transition", :resume, %w[withdrawn deferred], "active" do
    let(:instance) { described_class.new(lead_provider:, participant_id:, course_identifier:) }

    describe "validations" do
      context "when the application is already active" do
        let(:application) { create(:application, :accepted) }

        it { expect(instance).to have_error(:participant_id, :already_active, "The participant is already active") }
      end
    end
  end

  describe "email notifications" do
    let(:application) { create(:application, :accepted, :with_declaration, training_status:) }
    let(:instance) do
      described_class.new(
        lead_provider: application.lead_provider,
        participant_id: application.user.ecf_id,
        course_identifier: application.course.identifier,
      )
    end

    context "when the application was withdrawn" do
      let(:training_status) { "withdrawn" }

      it "sends a resumed notification email" do
        expect(ApplicationResumedMailer).to send_mail(:application_resumed_mail)
          .with_params(to: application.user.email,
                       full_name: application.user.full_name,
                       provider_name: application.lead_provider.name,
                       course_name: application.course.name,
                       ecf_id: application.ecf_id)
        instance.resume
      end

      context "when the participant has no email address" do
        before do
          application.user.update_columns(
            email: nil,
            archived_email: "archived@example.com",
            archived_at: Time.zone.now,
          )
        end

        it "does not send a resumed notification email" do
          expect(ApplicationResumedMailer).not_to send_mail(:application_resumed_mail)
          instance.resume
        end
      end

      context "when the application has a completed declaration" do
        before { create(:declaration, application:, declaration_type: "completed") }

        it "does not send a resumed notification email" do
          expect(ApplicationResumedMailer).not_to send_mail(:application_resumed_mail)
          instance.resume
        end
      end
    end

    context "when the application was deferred" do
      let(:training_status) { "deferred" }

      it "does not send a resumed notification email" do
        expect(ApplicationResumedMailer).not_to send_mail(:application_resumed_mail)
        instance.resume
      end

      # NPQ-3934: deferred to active notifications are turned off. Swap this
      # example when they are turned on again.
      #
      # it "sends a resumed notification email" do
      #   expect(ApplicationResumedMailer).to send_mail(:application_resumed_mail)
      #     .with_params(to: application.user.email,
      #                  full_name: application.user.full_name,
      #                  provider_name: application.lead_provider.name,
      #                  course_name: application.course.name,
      #                  ecf_id: application.ecf_id)
      #   instance.resume
      # end
    end
  end
end
