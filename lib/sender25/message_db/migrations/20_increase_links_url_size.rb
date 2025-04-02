# frozen_string_literal: true

module Sender25
  module MessageDB
    module Migrations
      class IncreaseLinksUrlSize < Sender25::MessageDB::Migration

        def up
          @database.query("ALTER TABLE `#{@database.database_name}`.`links` MODIFY `url` TEXT")
        end

      end
    end
  end
end
