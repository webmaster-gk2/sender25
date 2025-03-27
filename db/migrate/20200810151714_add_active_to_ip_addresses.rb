# frozen_string_literal: true

# Sender25 - Added active field to ip_addresses
class AddActiveToIPAddresses < ActiveRecord::Migration[5.0]
  def change
    add_column :ip_addresses, :active, :boolean, :default => true
  end
end
