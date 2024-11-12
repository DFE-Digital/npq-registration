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

  it { is_expected.to eq(expected_result) }
end
