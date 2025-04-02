#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/sender25/config"
require "mysql2"

client = Mysql2::Client.new(
  host: Sender25::Config.main_db.host,
  username: Sender25::Config.main_db.username,
  password: Sender25::Config.main_db.password,
  port: Sender25::Config.main_db.port,
  database: Sender25::Config.main_db.database
)
result = client.query("SELECT COUNT(id) as size FROM `queued_messages` WHERE retry_after IS NULL OR " \
                      "retry_after <= ADDTIME(UTC_TIMESTAMP(), '30') AND locked_at IS NULL")
puts result.to_a.first["size"]
