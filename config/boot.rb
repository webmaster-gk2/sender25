# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

$stdout.sync = true
$stderr.sync = true

require "bundler/setup" # Set up gems listed in the Gemfile.

require_relative "../lib/postal/config"
Postal.check_config!

ENV["RAILS_ENV"] = Postal.config.rails&.environment || "development"
