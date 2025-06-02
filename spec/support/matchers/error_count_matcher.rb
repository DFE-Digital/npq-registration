RSpec::Matchers.define :have_error_count do |count|
  match do |actual|
    actual.invalid? && actual.errors.count == count
  end

  failure_message do |actual|
    if actual.valid?
      "expected #{actual.class} to be invalid, but it was valid"
    else
      "expected #{actual.class} to have #{count} errors, but it had #{actual.errors.count} with messages: #{actual.errors.messages}"
    end
  end
end
