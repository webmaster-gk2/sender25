# frozen_string_literal: true

ENV["SILENCE_POSTAL_CONFIG_LOCATION_MESSAGE"] = "true"
require File.expand_path("../lib/sender25/config", __dir__)
puts Sender25.rp_dkim_dns_record
