# frozen_string_literal: true

# Sender25 - Added blacklist field to ip_addresses
class AddBlacklistToIPAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :ip_addresses, :blacklist, :boolean, :default => false

    IPAddress.find_each do |i|
      unless i.active
        i.active = 1
        i.blacklist = 1
        i.ipv4 = i.ipv4
        i.ipv6 = i.ipv6
        i.hostname = i.hostname
        i.save!
      end
    end
  end
end
