require "rails_helper"

RSpec.describe API::ParticipantSerializer, type: :serializer do
  let(:lead_provider) { create(:lead_provider) }
  let(:user) { create(:user) }
  let(:application) { create(:application, :eligible_for_funded_place, :with_participant_id_change, lead_provider:, funded_place: true, user:) }
  let(:course) { application.course }
  let(:school) { application.school }
  let(:participant_id_change) { application.participant_id_changes.last }
  let(:cohort) { application.cohort }
  let(:participant) { application.user }

  describe "core attributes" do
    subject(:response) { JSON.parse(described_class.render(participant, lead_provider:)) }

    it "serializes the `id`" do
      participant.ecf_id = "fe1a5280-1b13-4b09-b9c7-e2b01d37e851"

      expect(response["id"]).to eq("fe1a5280-1b13-4b09-b9c7-e2b01d37e851")
    end

    it "serializes the `type`" do
      response = JSON.parse(described_class.render(participant))

      expect(response["type"]).to eq("npq-participant")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { JSON.parse(described_class.render(participant, lead_provider:))["attributes"] }

    it "serializes the `full_name`" do
      expect(attributes["full_name"]).to eq(participant.full_name)
    end

    context "when serializing `previous_names`" do
      context "when the config flag is enabled" do
        let(:user) { create(:user, previous_names: ["Ben Smith", "Ben Doe"]) }

        before do
          allow(Rails.configuration.x.api).to receive(:previous_names).and_return(true)
        end

        it "serializes the `previous_names` array" do
          expect(attributes["previous_names"]).to eq(["Ben Smith", "Ben Doe"])
        end
      end

      context "when the config flag is disabled" do
        let(:user) { create(:user, previous_names: ["Ben Smith", "Ben Doe"]) }

        before do
          allow(Rails.configuration.x.api).to receive(:previous_names).and_return(false)
        end

        it "does not include the field" do
          expect(attributes).not_to have_key("previous_names")
        end
      end

      context "when the participant has no previous names" do
        let(:user) { create(:user, previous_names: []) }

        before do
          allow(Rails.configuration.x.api).to receive(:previous_names).and_return(true)
        end

        it "serializes an empty array" do
          expect(attributes["previous_names"]).to eq([])
        end
      end
    end

    context "when serializing `teacher_reference_number`" do
      context "when the TRN is verified" do
        let(:user) { create(:user, trn_verified: true) }

        it "serializes the `teacher_reference_number`" do
          expect(attributes["teacher_reference_number"]).to eq(participant.trn)
        end
      end

      context "when the TRN is not verified" do
        it "serializes nil" do
          expect(attributes["teacher_reference_number"]).to be_nil
        end
      end
    end

    context "when serializing `updated_at`" do
      let(:old_datetime) { Time.utc(2023, 5, 5, 5, 0, 0) }
      let(:latest_datetime) { Time.utc(2024, 8, 8, 8, 0, 0) }

      context "when participant is the latest" do
        it "serializes the `updated_at`" do
          application.update!(updated_at: old_datetime)
          participant_id_change.update!(updated_at: old_datetime)
          participant.update!(significantly_updated_at: latest_datetime)

          expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
        end
      end

      context "when application is the latest" do
        it "returns application's `updated_at`" do
          application.update!(updated_at: latest_datetime)
          participant_id_change.update!(updated_at: old_datetime)
          participant.update!(significantly_updated_at: old_datetime)

          expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
        end
      end

      context "when participant_id_change is the latest" do
        it "returns participant_id_change's `updated_at`" do
          application.update!(updated_at: old_datetime)
          participant_id_change.update!(updated_at: latest_datetime)
          participant.update!(significantly_updated_at: old_datetime)

          expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
        end
      end
    end

    it "serializes the `npq_enrolments`" do
      expect(attributes["npq_enrolments"]).to eq([
        {
          email: participant.email,
          course_identifier: application.course.identifier,
          schedule_identifier: application.schedule.identifier,
          cohort: application.cohort.start_year.to_s,
          npq_application_id: application.ecf_id,
          eligible_for_funding: application.eligible_for_funding,
          training_status: application.training_status,
          school_urn: application.school.urn,
          targeted_delivery_funding_eligibility: application.targeted_delivery_funding_eligibility,
          withdrawal: nil,
          deferral: nil,
          created_at: application.accepted_at.rfc3339,
          funded_place: application.funded_place,
        }.stringify_keys,
      ])
    end

    context "when application has been withdrawn" do
      let(:application) { create(:application, :withdrawn, :eligible_for_funded_place, lead_provider:, user:) }

      it "serializes the `npq_enrolments`" do
        expect(attributes["npq_enrolments"]).to eq([
          {
            email: participant.email,
            course_identifier: application.course.identifier,
            schedule_identifier: application.schedule.identifier,
            cohort: application.cohort.start_year.to_s,
            npq_application_id: application.ecf_id,
            eligible_for_funding: application.eligible_for_funding,
            training_status: application.training_status,
            school_urn: application.school.urn,
            targeted_delivery_funding_eligibility: application.targeted_delivery_funding_eligibility,
            withdrawal: {
              reason: application.application_states.last.reason,
              date: application.application_states.last.created_at.rfc3339,
            },
            deferral: nil,
            created_at: application.accepted_at.rfc3339,
            funded_place: application.funded_place,
          }.deep_stringify_keys,
        ])
      end
    end

    context "when application has been deferred" do
      let(:application) { create(:application, :deferred, :eligible_for_funded_place, lead_provider:, user:) }

      it "serializes the `npq_enrolments`" do
        expect(attributes["npq_enrolments"]).to eq([
          {
            email: participant.email,
            course_identifier: application.course.identifier,
            schedule_identifier: application.schedule.identifier,
            cohort: application.cohort.start_year.to_s,
            npq_application_id: application.ecf_id,
            eligible_for_funding: application.eligible_for_funding,
            training_status: application.training_status,
            school_urn: application.school.urn,
            targeted_delivery_funding_eligibility: application.targeted_delivery_funding_eligibility,
            withdrawal: nil,
            deferral: {
              reason: application.application_states.last.reason,
              date: application.application_states.last.created_at.rfc3339,
            },
            created_at: application.accepted_at.rfc3339,
            funded_place: application.funded_place,
          }.deep_stringify_keys,
        ])
      end
    end

    it "serializes the `participant_id_changes`" do
      expect(attributes["participant_id_changes"]).to eq([
        {
          from_participant_id: participant.participant_id_changes.last.from_participant_id,
          to_participant_id: participant.participant_id_changes.last.to_participant_id,
          changed_at: participant.participant_id_changes.last.created_at.rfc3339,
        }.stringify_keys,
      ])
    end

    context "when there're multiple application with different lead provider approval states" do
      before { create(:application, lead_provider:, user: participant) }

      it "serializes only accepted `npq_enrolments`" do
        expect(attributes["npq_enrolments"].size).to eq(1)
        expect(attributes["npq_enrolments"][0]["npq_application_id"]).to eq(application.ecf_id)
      end
    end
  end
end
