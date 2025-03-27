# frozen_string_literal: true

module Postal
  module Helpers

    def self.strip_name_from_address(address)
      return nil if address.nil?

      address.gsub(/.*</, "").gsub(/>.*/, "").gsub(/\(.+?\)/, "").strip.downcase
    end

    # Sender25 - Function to get the mx
    def self.return_mx_lookup(domain)
      mx_servers = []
      Resolv::DNS.open do |dns|
        dns.timeouts = [10,5]
        mx_servers = dns.getresources(domain, Resolv::DNS::Resource::IN::MX).map { |m| [m.preference.to_i, m.exchange.to_s] }.sort.map{ |m| m[1] }
        if mx_servers.empty?
          mx_servers = [domain] # No return MX using domain
        end
      end
      mx_servers
    end

  end
end
