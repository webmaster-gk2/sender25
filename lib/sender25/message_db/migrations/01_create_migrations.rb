# frozen_string_literal: true

module Sender25
  module MessageDB
    module Migrations
      class CreateMigrations < Sender25::MessageDB::Migration

        def up
          @database.provisioner.create_table(:migrations,
                                             columns: {
                                               version: "int(11) NOT NULL"
                                             },
                                             primary_key: "`version`")
        end

      end
    end
  end
end
