# frozen_string_literal: true

require "sender25/config"

if Sender25::Config.logging.sentry_dsn
  Sentry.init do |config|
    config.dsn = Sender25::Config.logging.sentry_dsn
  end
end
