RSpec::Matchers.define :have_error do |attribute, type, message, context|
  match do |actual|
    actual.invalid?(context) && actual.errors.any? do |error|
      error.attribute == attribute && error.type == type && error.message == message
    end
  end
end
