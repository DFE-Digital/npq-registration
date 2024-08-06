RSpec::Matchers.define :have_error do |attribute, type, message, context|
  match do |actual|
    actual.invalid?(context) && actual.errors.any? do |error|
      error_type_match = type.nil? || error.type == type
      error_message_match = message.nil? || error.message == message

      error.attribute == attribute && error_type_match && error_message_match
    end
  end
end
