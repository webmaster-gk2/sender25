class AddCustomDkimKeyToDomains < ActiveRecord::Migration[7.0]
  def change
    add_column :domains, :custom_dkim_key, :boolean, default: false, null: false
  end
end
