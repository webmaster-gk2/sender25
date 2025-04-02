# frozen_string_literal: true

module Sender25
  module MessageDB
    module Migrations
      class AddHoldExpiry < Sender25::MessageDB::Migration

        def up
          @database.query("ALTER TABLE `#{@database.database_name}`.`messages` ADD COLUMN `hold_expiry` decimal(18,6)")
        end

      end
    end
  end
end
