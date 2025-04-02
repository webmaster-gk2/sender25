# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

require_relative "../lib/sender25/config"

ENV["RAILS_ENV"] = Sender25::Config.rails.environment || "development"
