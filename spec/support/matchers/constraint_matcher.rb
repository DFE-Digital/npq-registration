RSpec::Matchers.define :constrain_attribute do |expected_attribute|
  match do |scope|
    string_attribute = expected_attribute.to_s
    scope.arel.constraints.any? { _1.left.name == string_attribute }
  end

  failure_message do |scope|
    "expected #{scope} to constrain #{expected_attribute}"
  end
end
