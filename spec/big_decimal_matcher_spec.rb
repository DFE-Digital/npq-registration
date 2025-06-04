require "rails_helper"

RSpec.describe "BigDecimal matcher" do
  let(:big_decimal_40) { BigDecimal("0.1372631578947368421052631578947368421064e4") }
  let(:big_decimal_34) { BigDecimal("0.1372631578947368421052631578947376e4") }

  it "matches BigDecimal numbers with at a precision of 28" do
    expect(big_decimal_40).to match_bigdecimal(big_decimal_34)
    expect(big_decimal_34).to match_bigdecimal(big_decimal_40)
  end

  it "does not match BigDecimal numbers that are totally different" do
    expect(big_decimal_40).not_to match_bigdecimal(BigDecimal("0.9564830485648405785521949564037659365947e4"))
  end

  it "check it matches the failures from the failing build" do
    # failures from this build: https://github.com/DFE-Digital/npq-registration/actions/runs/15354218458/job/43209495969
    [
      %w[0.2446631578947368421052631578947368421064e4 0.2446631578947368421052631578947376e4],
      %w[0.1212631578947368421052631578947368421064e4 0.1212631578947368421052631578947376e4],
      %w[0.1262631578947368421052631578947368421064e4 0.1262631578947368421052631578947376e4],
      %w[0.1472631578947368421052631578947368421064e4 0.1472631578947368421052631578947376e4],
      %w[0.1372631578947368421052631578947368421064e4 0.1372631578947368421052631578947376e4],
      %w[0.16842105263157894736842105263157894737e2 0.16842105263157894736842105263158e2],
      %w[0.12402054794520547945205479452054794521e2 0.12402054794520547945205479452055e2],
    ].each do |expected, actual|
      expect(BigDecimal(actual)).to match_bigdecimal(BigDecimal(expected))
    end
  end
end
