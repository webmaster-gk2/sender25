#!/usr/bin/env ruby
# frozen_string_literal: true

# Sender25 - Added script to unlock queue
require_relative "../lib/postal/config"
require "mysql2"

client = Mysql2::Client.new(
  host: Postal.config.main_db.host,
  username: Postal.config.main_db.username,
  password: Postal.config.main_db.password,
  port: Postal.config.main_db.port,
  database: Postal.config.main_db.database
)
client.query("UPDATE `queued_messages` SET locked_by = NULL, locked_at = NULL, retry_after = NULL")
