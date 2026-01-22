# frozen_string_literal: true

Sentry.init do |config|
  config.enabled_environments = %w[production sandbox staging review]
  config.dsn = config.enabled_environments.include?(Rails.env) ? ENV["SENTRY_DSN"] : "disabled"
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.release = ENV["GIT_COMMIT_SHA"]

  # filtering code taken from https://docs.sentry.io/platforms/ruby/guides/rails/configuration/filtering/
  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.before_send = lambda do |event, _hint|
    # Sanitize extra data
    if event.extra
      event.extra = filter.filter(event.extra)
    end

    # Sanitize user data
    if event.user
      event.user = filter.filter(event.user)
    end

    # Sanitize context data (if present)
    if event.contexts
      event.contexts = filter.filter(event.contexts)
    end

    # Return the sanitized event object
    event
  end

  config.excluded_exceptions += %w[
    SessionWizard::InvalidStep
  ]

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
