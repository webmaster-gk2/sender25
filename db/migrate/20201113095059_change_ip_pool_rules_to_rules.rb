# frozen_string_literal: true

# Sender25 - Added relational table for custom rules
class ChangeIPPoolRulesToRules < ActiveRecord::Migration[5.2]
  def change
    rename_table :ip_pool_rules, :rules

    Rule.find_each do |r|
      ip_pool_ids = []
      ip_pool_ids << r.ip_pool_id
      r.ip_pool_ids = ip_pool_ids
      r.save!
    end

    remove_column :rules, :ip_pool_id, :integer
  end
end
