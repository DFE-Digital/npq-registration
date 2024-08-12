require "rails_helper"

RSpec.describe API::ParticipantSerializer, type: :serializer do
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { application.course }
  let(:school) { application.school }
  let(:participant_id_change) { application.participant_id_changes.last }
  let(:cohort) { application.cohort }
  let(:application) { create(:application, :eligible_for_funded_place, :with_participant_id_change, lead_provider:, funded_place: true) }
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
    context "when serializing the `v1` view" do
      subject(:attributes) { JSON.parse(described_class.render(participant, lead_provider:, view: :v1))["attributes"] }

      it "serializes the `participant_id`" do
        expect(attributes["participant_id"]).to eq(participant.ecf_id)
      end

      it "serializes the `full_name`" do
        expect(attributes["full_name"]).to eq(participant.full_name)
      end

      it "serializes the `email`" do
        expect(attributes["email"]).to eq(participant.email)
      end

      it "serializes the `npq_courses`" do
        expect(attributes["npq_courses"]).to eq([course.identifier])
      end

      it "serializes the `funded_places`" do
        expect(attributes["funded_places"]).to eq([
          {
            npq_course: application.course.identifier,
            funded_place: application.funded_place,
            npq_application_id: application.ecf_id,
          }.stringify_keys,
        ])
      end

      it "serializes the `teacher_reference_number`" do
        expect(attributes["teacher_reference_number"]).to eq(participant.trn)
      end

      context "when serializing `updated_at`" do
        let(:old_datetime) { Time.utc(2023, 5, 5, 5, 0, 0) }
        let(:latest_datetime) { Time.utc(2024, 8, 8, 8, 0, 0) }

        context "when participant is the latest" do
          it "serializes the `updated_at`" do
            application.update!(updated_at: old_datetime)
            participant_id_change.update!(updated_at: old_datetime)
            participant.update!(updated_at: latest_datetime)

            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end

        context "when application is the latest" do
          it "returns application's `updated_at`" do
            application.update!(updated_at: latest_datetime)
            participant_id_change.update!(updated_at: old_datetime)
            participant.update!(updated_at: old_datetime)

            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end

        context "when participant_id_change is the latest" do
          it "returns participant_id_change's `updated_at`" do
            application.update!(updated_at: old_datetime)
            participant_id_change.update!(updated_at: latest_datetime)
            participant.update!(updated_at: old_datetime)

            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end
      end
    end

    context "when serializing the `v2` view" do
      subject(:attributes) { JSON.parse(described_class.render(participant, lead_provider:, view: :v2))["attributes"] }

      it "serializes the `email`" do
        expect(attributes["email"]).to eq(participant.email)
      end

      it "serializes the `full_name`" do
        expect(attributes["full_name"]).to eq(participant.full_name)
      end

      it "serializes the `teacher_reference_number`" do
        expect(attributes["teacher_reference_number"]).to eq(participant.trn)
      end

      context "when serializing `updated_at`" do
        let(:old_datetime) { Time.utc(2023, 5, 5, 5, 0, 0) }
        let(:latest_datetime) { Time.utc(2024, 8, 8, 8, 0, 0) }

        context "when participant is the latest" do
          it "serializes the `updated_at`" do
            application.update!(updated_at: old_datetime)
            participant_id_change.update!(updated_at: old_datetime)
            participant.update!(updated_at: latest_datetime)

            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end

        context "when application is the latest" do
          it "returns application's `updated_at`" do
            application.update!(updated_at: latest_datetime)
            participant_id_change.update!(updated_at: old_datetime)
            participant.update!(updated_at: old_datetime)

            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end

        context "when participant_id_change is the latest" do
          it "returns participant_id_change's `updated_at`" do
            application.update!(updated_at: old_datetime)
            participant_id_change.update!(updated_at: latest_datetime)
            participant.update!(updated_at: old_datetime)

            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end
      end

      it "serializes the `npq_enrolments`" do
        expect(attributes["npq_enrolments"]).to eq([
          {
            course_identifier: application.course.identifier,
            schedule_identifier: application.schedule.identifier,
            cohort: application.cohort.start_year.to_s,
            npq_application_id: application.ecf_id,
            eligible_for_funding: application.eligible_for_funding,
            training_status: application.training_status,
            school_urn: application.school.urn,
            targeted_delivery_funding_eligibility: application.targeted_delivery_funding_eligibility,
            funded_place: application.funded_place,
          }.stringify_keys,
        ])
      end
    end

    context "when serializing the `v3` view" do
      subject(:attributes) { JSON.parse(described_class.render(participant, lead_provider:, view: :v3))["attributes"] }

      it "serializes the `full_name`" do
        expect(attributes["full_name"]).to eq(participant.full_name)
      end

      it "serializes the `teacher_reference_number`" do
        expect(attributes["teacher_reference_number"]).to eq(participant.trn)
      end

      context "when serializing `updated_at`" do
        let(:old_datetime) { Time.utc(2023, 5, 5, 5, 0, 0) }
        let(:latest_datetime) { Time.utc(2024, 8, 8, 8, 0, 0) }

        context "when participant is the latest" do
          it "serializes the `updated_at`" do
            application.update!(updated_at: old_datetime)
            participant_id_change.update!(updated_at: old_datetime)
            participant.update!(updated_at: latest_datetime)

            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end

        context "when application is the latest" do
          it "returns application's `updated_at`" do
            application.update!(updated_at: latest_datetime)
            participant_id_change.update!(updated_at: old_datetime)
            participant.update!(updated_at: old_datetime)

            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end

        context "when participant_id_change is the latest" do
          it "returns participant_id_change's `updated_at`" do
            application.update!(updated_at: old_datetime)
            participant_id_change.update!(updated_at: latest_datetime)
            participant.update!(updated_at: old_datetime)

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
        let(:application) { create(:application, :withdrawn, :eligible_for_funded_place, lead_provider:) }

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
        let(:application) { create(:application, :deferred, :eligible_for_funded_place, lead_provider:) }

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
            from_participant_id: participant.participant_id_changes.last.from_participant.ecf_id,
            to_participant_id: participant.participant_id_changes.last.to_participant.ecf_id,
            changed_at: participant.participant_id_changes.last.created_at.rfc3339,
          }.stringify_keys,
        ])
      end
    end
  end
end
