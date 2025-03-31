RSpec::Matchers.define :have_error do |attribute, type, message, context|
  match do |actual|
    actual.invalid?(context) && actual.errors.any? do |error|
      error_type_match = type.nil? || error.type == type
      error_message_match = message.nil? || error.message == message

      error.attribute == attribute && error_type_match && error_message_match
    end
  end

  failure_message do |actual|
    actual.errors.map { |error|
      "expected error on :#{attribute} with type :#{type} and message \"#{message}\", but got :#{error.attribute} with type :#{error.type} and message \"#{error.message}\""
    }.join(" and ")
  end
end
