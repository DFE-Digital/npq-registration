# frozen_string_literal: true

Sentry.init do |config|
  config.enabled_environments = %w[production separation]
  config.dsn = config.enabled_environments.include?(Rails.env) ? ENV["SENTRY_DSN"] : "disabled"
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.release = ENV["GIT_COMMIT_SHA"]

  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.before_send = lambda do |event, _hint|
    # use Rails' parameter filter to sanitize the event
    filter.filter(event.to_hash)
  end

  config.traces_sampler = lambda do |sampling_context|
    transaction_context = sampling_context[:transaction_context]
    op = transaction_context[:op]
    transaction_name = transaction_context[:name]

    case op
    when /request/
      case transaction_name
      when /healthcheck/
        0.0 # ignore healthcheck requests
      else
        0.01
      end
    else
      0.0 # We don't care about performance of other things
    end
  end
end
