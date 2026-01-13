require "rails_helper"

RSpec.describe API::ParticipantOutcomeSerializer, type: :serializer do
  let(:outcome) { create(:participant_outcome) }

  describe "core attributes" do
    subject(:response) { JSON.parse(described_class.render(outcome)) }

    it "serializes the `id`" do
      outcome.ecf_id = "fe1a5280-1b13-4b09-b9c7-e2b01d37e851"

      expect(response["id"]).to eq("fe1a5280-1b13-4b09-b9c7-e2b01d37e851")
    end

    it "serializes the `type`" do
      response = JSON.parse(described_class.render(outcome))

      expect(response["type"]).to eq("participant-outcome")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { JSON.parse(described_class.render(outcome))["attributes"] }

    it "serializes the `state`" do
      expect(attributes["state"]).to eq(outcome.state)
    end

    it "serializes the `completion_date`" do
      expect(attributes["completion_date"]).to eq(outcome.completion_date.rfc3339)
    end

    it "serializes the `course_identifier`" do
      expect(attributes["course_identifier"]).to eq(outcome.declaration.application.course.identifier)
    end

    it "serializes the `participant_id`" do
      expect(attributes["participant_id"]).to eq(outcome.user.ecf_id)
    end

    it "serializes the `created_at`" do
      expect(attributes["created_at"]).to eq(outcome.created_at.rfc3339)
    end

    it "serializes the `updated_at`" do
      expect(attributes["updated_at"]).to eq(outcome.updated_at.rfc3339)
    end
  end
end
