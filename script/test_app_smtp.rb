#!/usr/bin/env ruby
# frozen_string_literal: true

trap("INT") do
  puts
  exit
end

if ARGV[0].nil? || ARGV[0] !~ /@/
  puts "usage: sender25 test-app-smtp [email address]"
  exit 1
end

require_relative "../config/environment"

begin
  Timeout.timeout(10) do
    AppMailer.test_message(ARGV[0]).deliver
  end

  puts "\e[32mMessage has been sent successfully.\e[0m"
rescue Timeout::Error
  puts "Sending timed out"
rescue StandardError => e
  puts "\e[31mMessage was not delivered successfully to SMTP server.\e[0m"
  puts "Error: #{e.class} (#{e.message})"
  puts
  puts "  SMTP Host: #{Sender25::Config.smtp.host}"
  puts "  SMTP Port: #{Sender25::Config.smtp.port}"
  puts "  SMTP Username: #{Sender25::Config.smtp.username}"
  puts "  SMTP Password: #{Sender25::Config.smtp.password}"
  puts
end
