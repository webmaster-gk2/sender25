# frozen_string_literal: true

module Postal
  module MessageDB
    class SuppressionList

      def initialize(database)
        @database = database
      end

      def add(type, address, options = {})
        keep_until = (options[:days] || Postal.config.general.suppression_list_removal_delay).days.from_now.to_f
        # Sender25 - Added database parameter
        if existing = @database.select("suppressions", where: { type: type, address: address }, limit: 1, dbname: Postal.config.main_db.database ).first
          reason = options[:reason] || existing["reason"]
          # Sender25 - Added database parameter
          @database.update("suppressions", { reason: reason, keep_until: keep_until }, where: { id: existing["id"] }, dbname: Postal.config.main_db.database )
        else
          # Sender25 - Added database parameter
          @database.insert("suppressions", { type: type, address: address, reason: options[:reason], timestamp: Time.now.to_f, keep_until: keep_until }, dbname: Postal.config.main_db.database )
        end
        true
      end

      def get(type, address)
        # Sender25 - Added database parameter
        @database.select("suppressions", where: { type: type, address: address, keep_until: { greater_than_or_equal_to: Time.now.to_f } }, limit: 1, dbname: Postal.config.main_db.database ).first
      end

      def all_with_pagination(page)
        # Sender25 - Added database parameter
        @database.select_with_pagination(:suppressions, page, order: :timestamp, direction: "desc", dbname: Postal.config.main_db.database )
      end

      def remove(type, address)
        # Sender25 - Added database parameter
        @database.delete("suppressions", where: { type: type, address: address }, dbname: Postal.config.main_db.database ).positive?
      end

      def prune
        # Sender25 - Added database parameter
        @database.delete("suppressions", where: { keep_until: { less_than: Time.now.to_f } }, dbname: Postal.config.main_db.database ) || 0
      end

    end
  end
end
