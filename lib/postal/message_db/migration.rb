# frozen_string_literal: true

module Postal
  module MessageDB
    class Migration

      def initialize(database)
        @database = database
      end

      def up
      end

      def self.run(database, start_from: database.schema_version, silent: false)
        files = Dir[Rails.root.join("lib", "postal", "message_db", "migrations", "*.rb")]
        files = files.map do |f|
          id, name = f.split("/").last.split("_", 2)
          [id.to_i, name]
        end.sort_by(&:first)

        latest_version = files.last.first
        if latest_version <= start_from
          puts "Nothing to do" unless silent
          return false
        end

        unless silent
          puts "\e[32mMigrating #{database.database_name} from version #{start_from} => #{files.last.first}\e[0m"
        end

        files.each do |version, file|
          klass_name = file.gsub(/\.rb\z/, "").camelize
          next if start_from >= version

          puts "\e[45m++ Migrating #{klass_name} (#{version})\e[0m" unless silent
          require "postal/message_db/migrations/#{version.to_s.rjust(2, '0')}_#{file}"
          klass = Postal::MessageDB::Migrations.const_get(klass_name)
          instance = klass.new(database)
          instance.up
          database.insert(:migrations, version: version)
        end
      end

    end
  end
end
