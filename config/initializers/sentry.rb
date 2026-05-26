Sentry.init do |config|
  config.dsn                  = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[production staging]
  config.breadcrumbs_logger   = [:active_support_logger, :http_logger]
  config.traces_sample_rate   = 0.1

  config.before_send = lambda do |event, hint|
    ex = hint[:exception]
    return nil if ex.is_a?(ActionController::RoutingError)
    return nil if ex.is_a?(ActionController::UnknownFormat)
    return nil if ex.is_a?(ActiveRecord::RecordNotFound) && hint[:rack_env].present?
    event
  end
end
