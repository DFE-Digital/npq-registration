# The precision of BigDecimal is platform-dependent
# To avoid problems with running specs on different platforms, use this matcher instead of `eq` or `==` for BigDecimal comparisons.
# The BigDecimal precision is normally 40, but we've it drop to 34 in some cases when running specs in a github workflow.
# The precision has been determined by looking at the spec failures here: https://github.com/DFE-Digital/npq-registration/actions/runs/15354218458/job/43209495969
RSpec::Matchers.define :match_bigdecimal do |expected|
  rounding_precision = 28

  match do |actual|
    expected.round(rounding_precision) == actual.round(rounding_precision)
  end

  failure_message do |actual|
    "\nexpected #{expected}\nto match #{actual}, but they are not equal" \
      "\nvalues used in comparison:\n  expected: #{expected.round(rounding_precision)}" \
      "\n  actual:   #{actual.round(rounding_precision)}\n" \
  end
end
