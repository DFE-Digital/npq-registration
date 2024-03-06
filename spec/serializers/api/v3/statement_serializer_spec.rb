# spec/serializers/api/v1/statement_serializer_spec.rb

require "rails_helper"

RSpec.describe API::V3::StatementSerializer, type: :serializer do
  let(:subject) { described_class }
  let(:cohort) { create(:cohort) }
  let(:statement) { create(:statement, cohort:) }

  it "serializes the `id`" do
    response = subject.render_as_hash(statement)

    expect(response[:id]).to eq(statement.id)
  end

  it "serializes the `cohort start year`" do
    cohort.start_year = 2025
    response = subject.render_as_hash(statement)

    expect(response[:cohort]).to eq(2025)
  end

  it "serializes the `month`" do
    statement.month = 7
    response = subject.render_as_hash(statement)

    expect(response[:month]).to eq(7)
  end

  it "serializes the `year`" do
    statement.year = 2023
    response = subject.render_as_hash(statement)

    expect(response[:year]).to eq(2023)
  end

  it "defaults `type` to `npq` for compatibility reasons" do
    response = subject.render_as_hash(statement)

    expect(response[:type]).to eq("npq")
  end

  it "serializes the `deadline`" do
    statement.deadline_date = Date.new(2023, 7, 1)
    response = subject.render_as_hash(statement)

    expect(response[:cut_off_date]).to eq("2023-07-01")
  end

  it "serializes the `payment_date`" do
    statement.payment_date = Date.new(2023, 7, 1)
    response = subject.render_as_hash(statement)

    expect(response[:payment_date]).to eq("2023-07-01")
  end

  describe "`paid` status" do
    it "returns `true` when `payment_date` is not nil" do
      statement.payment_date = Date.new(2023, 7, 1)
      response = subject.render_as_hash(statement)

      expect(response[:paid]).to eq(true)
    end

    it "returns `false` when `payment_date` is nil" do
      statement.payment_date = nil
      response = subject.render_as_hash(statement)

      expect(response[:paid]).to eq(false)
    end
  end

  describe "timestamp serialization" do
    it "serializes the `created_at`" do
      statement.created_at = Time.utc(2023, 7, 1, 12, 0, 0)
      response = subject.render_as_hash(statement)

      expect(response[:created_at]).to eq("2023-07-01T12:00:00Z")
    end

    it "serializes the `updated_at`" do
      statement.updated_at = Time.utc(2023, 7, 2, 12, 0, 0)
      response = subject.render_as_hash(statement)

      expect(response[:updated_at]).to eq("2023-07-02T12:00:00Z")
    end
  end
end
