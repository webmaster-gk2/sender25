# frozen_string_literal: true

# Sender25 - Added table for custom roles
class CreateRuleIPPools < ActiveRecord::Migration[5.2]
  def up
    create_table "rule_ip_pools", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
      t.integer "rule_id"
      t.integer "ip_pool_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
