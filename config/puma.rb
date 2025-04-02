# frozen_string_literal: true

require_relative "../lib/sender25/config"

threads_count = Sender25::Config.web_server.max_threads
threads         threads_count, threads_count
bind_address  = ENV.fetch("BIND_ADDRESS", Sender25::Config.web_server.default_bind_address)
bind_port     = ENV.fetch("PORT", Sender25::Config.web_server.default_port)
bind            "tcp://#{bind_address}:#{bind_port}"
environment     Sender25::Config.rails.environment || "development"
prune_bundler
quiet false
