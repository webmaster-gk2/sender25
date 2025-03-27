# frozen_string_literal: true

# Sender25 - Added custom_spf field to servers
class AddCustomSpfToServers < ActiveRecord::Migration[5.2]
  def change
    add_column :servers, :custom_spf, :string
  end
end
