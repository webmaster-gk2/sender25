# frozen_string_literal: true

module Sender25
  module MessageDB
    module Migrations
      class AddIndexToMessageStatus < Sender25::MessageDB::Migration

        def up
          @database.query("ALTER TABLE `#{@database.database_name}`.`messages` ADD INDEX `on_status` (`status`(8)) USING BTREE")
        end

      end
    end
  end
end
