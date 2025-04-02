# frozen_string_literal: true

module Sender25
  module MessageDB
    module Migrations
      class AddEndpointsToMessages < Sender25::MessageDB::Migration

        def up
          @database.query("ALTER TABLE `#{@database.database_name}`.`messages` ADD COLUMN `endpoint_id` int(11), ADD COLUMN `endpoint_type` varchar(255)")
        end

      end
    end
  end
end
