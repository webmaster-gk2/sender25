# frozen_string_literal: true

# Sender25 - Added model for global suppression table
# == Schema Information
#
# Table name: suppressions
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  address     :string(255)
#  reason      :string(255)
#  timestamp   :decimal(18, 6)
#  keep_until  :decimal(18, 6)
#
# Indexes
#
#  index_suppressions_on_address     (address)
#  index_suppressions_on_keep_until  (keep_until)
#

class Suppression < ApplicationRecord

  #
  # Selects entries from the database. Accepts a number of options which can be used
  # to manipulate the results.
  #
  #   :where     => A hash containing the query
  #   :order     => The name of a field to order by
  #   :direction => The order that should be applied to ordering (ASC or DESC)
  #   :fields    => An array of fields to select
  #   :limit     => Limit the number of results
  #   :page      => Which page number to return
  #   :per_page  => The number of items per page (defaults to 30)
  #   :count     => Return a count of the results instead of the actual data
  #
  def select(table, options = {})
    sql_query = "SELECT"
    if options[:count]
      sql_query << " COUNT(id) AS count"
    elsif options[:fields]
      sql_query << " " + options[:fields].map { |f| "`#{f}`" }.join(", ")
    else
      sql_query << " *"
    end
    sql_query << " FROM `"
    sql_query << Postal.config.main_db.database
    sql_query << "`.`#{table}`"
    if options[:where] && !options[:where].empty?
      sql_query << " " + build_where_string(options[:where], " AND ")
    end
    if options[:order]
      direction = (options[:direction] || 'ASC').upcase
      raise Postal::Error, "Invalid direction #{options[:direction]}" unless ["ASC", "DESC"].include?(direction)
      sql_query << " ORDER BY `#{options[:order]}` #{direction}"
    end

    if options[:limit]
      sql_query << " LIMIT #{options[:limit]}"
    end

    if options[:offset]
      sql_query << " OFFSET #{options[:offset]}"
    end

    result = query(sql_query)
    if options[:count]
      result.first["count"]
    else
      result.to_a
    end
  end

  #
  # A paginated version of select
  #
  def select_with_pagination(table, page, options = {})
    page = page.to_i
    page = 1 if page <= 0

    per_page = options.delete(:per_page) || 500
    offset = (page - 1) * per_page

    result = {}
    result[:total] = select(table, options.merge(:count => true))
    result[:records] = select(table, options.merge(:limit => per_page, :offset => offset))
    result[:per_page] = per_page
    result[:total_pages], remainder = result[:total].divmod(per_page)
    result[:total_pages] += 1 if remainder > 0
    result[:page] = page
    result
  end
end
