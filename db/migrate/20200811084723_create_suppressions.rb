# frozen_string_literal: true

# Sender25 - Added table of global suppression list
class CreateSuppressions < ActiveRecord::Migration[5.0]
  def up
    create_table "suppressions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
      t.string "type"
      t.string "address"
      t.string "reason"
      t.decimal "timestamp", precision: 18, scale: 6
      t.decimal "keep_until", precision: 18, scale: 6
      t.index ["address"], name: "index_suppressions_on_address", length: { address: 6 }, using: :btree
      t.index ["keep_until"], name: "index_suppressions_on_keep_until", using: :btree
    end
  end
end
