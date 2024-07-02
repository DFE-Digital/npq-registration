require "rails_helper"

class ControllerWithFilterByDate
  include API::FilterByDate

  public :updated_since, :created_since

  def initialize(updated_since_param:, created_since_param:)
    @updated_since_param = updated_since_param
    @created_since_param = created_since_param
  end

private

  def params
    {
      filter: {
        updated_since: @updated_since_param,
        created_since: @created_since_param,
      },
    }
  end
end

RSpec.describe API::FilterByDate do
  let(:expected_updated_since) { Time.zone.local(2022, 2, 1, 10, 30) }
  let(:expected_created_since) { Time.zone.local(2023, 3, 2, 11, 45) }

  let(:updated_since_param) { expected_updated_since.rfc3339 }
  let(:created_since_param) { expected_created_since.rfc3339 }

  let(:instance) { ControllerWithFilterByDate.new(updated_since_param:, created_since_param:) }

  describe "#updated_since" do
    subject { instance.updated_since }

    it { is_expected.to eq(expected_updated_since) }

    context "when the updated_since filter is not present" do
      let(:updated_since_param) { nil }

      it { is_expected.to be_nil }
    end

    context "when the updated_since filter is not an ISO8601 date" do
      let(:updated_since_param) { "invalid-date" }

      it { expect { subject }.to raise_error(ActionController::BadRequest).with_message(I18n.t(:invalid_date_filter, attribute: :updated_since)) }
    end
  end

  describe "#created_since" do
    subject { instance.created_since }

    it { is_expected.to eq(expected_created_since) }

    context "when the created_since filter is not present" do
      let(:created_since_param) { nil }

      it { is_expected.to be_nil }
    end

    context "when the created_since filter is not an ISO8601 date" do
      let(:created_since_param) { "invalid-date" }

      it { expect { subject }.to raise_error(ActionController::BadRequest).with_message(I18n.t(:invalid_date_filter, attribute: :created_since)) }
    end
  end
end
