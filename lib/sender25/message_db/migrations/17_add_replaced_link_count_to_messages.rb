# frozen_string_literal: true

module Sender25
  module MessageDB
    module Migrations
      class AddReplacedLinkCountToMessages < Sender25::MessageDB::Migration

        def up
          @database.query("ALTER TABLE `#{@database.database_name}`.`messages` ADD COLUMN `tracked_links` int(11) DEFAULT 0")
          @database.query("ALTER TABLE `#{@database.database_name}`.`messages` ADD COLUMN `tracked_images` int(11) DEFAULT 0")
          @database.query("ALTER TABLE `#{@database.database_name}`.`messages` ADD COLUMN `parsed` tinyint DEFAULT 0")
        end

      end
    end
  end
end
