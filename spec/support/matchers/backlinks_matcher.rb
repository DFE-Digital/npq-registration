RSpec::Matchers.define :match_backlinks do |expected|
  match do |actual|
    expect(expected).to match_array(actual)
  end

  failure_message do |actual|
    message = "actual steps: #{actual.reverse}\nshould match expected steps: #{expected.reverse}, but they are not equal\n"
    missing_steps = expected - actual
    extra_steps = actual - expected

    if missing_steps.any?
      message += "missing_steps: #{missing_steps}\n"
      last_missing_step = missing_steps.last
      step = expected[expected.index(last_missing_step) + 1]
      step = "the last step" if step.nil?
      message += "clicking back on #{step} should have taken you to #{last_missing_step} " \
        "instead of #{actual[actual.index(step) - 1]}\n"
    end
    if extra_steps.any?
      message += "extra_steps: #{extra_steps}\n"
      last_extra_step = extra_steps.last
      step = actual[actual.index(last_extra_step) + 1]
      message += "clicking back on #{step} should have taken you to #{expected[expected.index(step) - 1]} " \
        "instead of #{actual[actual.index(step) - 1]}\n"
    end
    message
  end
end
