# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::ServiceFeesCalculator do
  subject { described_class.call(contract:) }

  let(:contract) { create :contract }

  let(:expected_result) do
    {
      monthly: BigDecimal("0.1212631578947368421052631578947368421064e4"),
      per_participant: BigDecimal("0.16842105263157894736842105263157894737e2"),
    }
  end

  it "calculates the correct monthly service fee" do
    expect(subject[:monthly]).to match_bigdecimal(expected_result[:monthly])
  end

  it "calculates the correct per participant service fee" do
    expect(subject[:per_participant]).to match_bigdecimal(expected_result[:per_participant])
  end
end
