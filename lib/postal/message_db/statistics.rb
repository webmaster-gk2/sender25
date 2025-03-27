# frozen_string_literal: true

module Postal
  module MessageDB
    class Statistics

      def initialize(database)
        @database = database
      end

      STATS_GAPS = { hourly: :hour, daily: :day, monthly: :month, yearly: :year }.freeze
      COUNTERS = [:incoming, :outgoing, :spam, :bounces, :held].freeze

      #
      # Increment an appropriate counter
      #
      def increment_one(type, field, time = Time.now)
        # Sender25 - Added timezone functionality
        time = time.in_time_zone
        initial_values = COUNTERS.map do |c|
          field.to_sym == c ? 1 : 0
        end

        # Sender25 - Added timezone functionality
        time_i = time.send("beginning_of_#{STATS_GAPS[type]}").in_time_zone.to_i
        sql_query = "INSERT INTO `#{@database.database_name}`.`stats_#{type}` (time, #{COUNTERS.join(', ')})"
        sql_query << " VALUES (#{time_i}, #{initial_values.join(', ')})"
        sql_query << " ON DUPLICATE KEY UPDATE #{field} = #{field} + 1"
        @database.query(sql_query)
      end

      #
      # Increment all stats counters
      #
      def increment_all(time, field)
        # Sender25 - Added timezone functionality
        current_timezone = Time.zone
        begin
          sql_query = "SELECT time_zone FROM `"
          sql_query << Postal.config.main_db.database
          sql_query << "`.`organizations` WHERE id = "
          sql_query << @database.organization_id.to_s
          if orgselected = @database.query(sql_query).first
            Time.zone = orgselected['time_zone']
          end
        rescue
          Time.zone = current_timezone
        end

        time = time.in_time_zone
        STATS_GAPS.each_key do |type|
          increment_one(type, field, time)
        end

        Time.zone = current_timezone
      end

      #
      # Get a statistic (or statistics)
      #
      def get(type, counters, start_date = Time.now, quantity = 10)
        # Sender25 - Added timezone functionality
        current_timezone = Time.zone
        begin
          sql_query = "SELECT time_zone FROM `"
          sql_query << Postal.config.main_db.database
          sql_query << "`.`organizations` WHERE id = "
          sql_query << @database.organization_id.to_s
          if orgselected = @database.query(sql_query).first
            Time.zone = orgselected['time_zone']
          end
        rescue
          Time.zone = current_timezone
        end
        start_date = start_date.in_time_zone
        items = quantity.times.each_with_object({}) do |i, hash|
          hash[(start_date - i.send(STATS_GAPS[type])).send("beginning_of_#{STATS_GAPS[type]}").in_time_zone] = counters.each_with_object({}) do |c, h|
            h[c] = 0
          end
        end
        @database.select("stats_#{type}", where: { time: items.keys.map(&:to_i) }, fields: [:time] | counters).each do |data|
          time = Time.zone.at(data.delete("time"))
          data.each do |key, value|
            items[time][key.to_sym] = value
          end
        end
        Time.zone = current_timezone
        items.to_a.reverse
      end

    end
  end
end
