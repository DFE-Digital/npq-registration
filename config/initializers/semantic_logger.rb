# Log actual exceptions, not a string representation
ActionDispatch::DebugExceptions.class_eval do
private

  undef_method :log_error
  def log_error(_request, wrapper)
    Rails.application.deprecators.silence do
      ActionController::Base.logger.fatal(wrapper.exception)
    end
  end
end
