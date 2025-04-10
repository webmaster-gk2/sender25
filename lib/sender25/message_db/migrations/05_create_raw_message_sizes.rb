# frozen_string_literal: true

module Sender25
  module MessageDB
    module Migrations
      class CreateRawMessageSizes < Sender25::MessageDB::Migration

        def up
          @database.provisioner.create_table(:raw_message_sizes,
                                             columns: {
                                               id: "int(11) NOT NULL AUTO_INCREMENT",
                                               table_name: "varchar(255) DEFAULT NULL",
                                               size: "bigint DEFAULT NULL"
                                             },
                                             indexes: {
                                               on_table_name: "`table_name`(14)"
                                             })
        end

      end
    end
  end
end
