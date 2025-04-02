class RemoveDKIMIdentifierString < ActiveRecord::Migration[7.0]
  def change
    remove_column :domains, :dkim_identifier_string, :string
  end
end
