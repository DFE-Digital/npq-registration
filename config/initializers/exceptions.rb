ActionDispatch::ExceptionWrapper.rescue_responses.merge!(
  "SessionWizard::InvalidStep" => :not_found,
)
