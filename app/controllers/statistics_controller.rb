# frozen_string_literal: true

# Sender25 - Added controller for statistics
class StatisticsController < ApplicationController

  include WithinOrganization

  before_action { @server = organization.servers.present.find_by_permalink!(params[:server_id]) }

  def index
    Time.zone = organization.time_zone
    t_server_create = @server.created_at
    t_first_day = Time.local(t_server_create.year, t_server_create.month, 1, 0, 0, 0)
    t_last_day = t_first_day.+1.months.-1.seconds
    t_now = Time.now.in_time_zone

    @statistics = []

    loop do
      statistic = {:t_first_day => t_first_day, :t_last_day => t_last_day}

      statistic[:outgoing] = @server.statistic_messages({:scope => 'outgoing', :time_start => t_first_day, :time_end => t_last_day})
      statistic[:outgoing_bounce] = @server.statistic_messages({:scope => 'outgoing', :time_start => t_first_day, :time_end => t_last_day, :bounce => 1})
      statistic[:outgoing_spam] = @server.statistic_messages({:scope => 'outgoing', :time_start => t_first_day, :time_end => t_last_day, :spam => 1})
      statistic[:outgoing_held] = @server.statistic_messages({:scope => 'outgoing', :time_start => t_first_day, :time_end => t_last_day, :held => 1})

      statistic[:incoming] = @server.statistic_messages({:scope => 'incoming', :time_start => t_first_day, :time_end => t_last_day})
      statistic[:incoming_bounce] = @server.statistic_messages({:scope => 'incoming', :time_start => t_first_day, :time_end => t_last_day, :bounce => 1})
      statistic[:incoming_spam] = @server.statistic_messages({:scope => 'incoming', :time_start => t_first_day, :time_end => t_last_day, :spam => 1})
      statistic[:incoming_held] = @server.statistic_messages({:scope => 'incoming', :time_start => t_first_day, :time_end => t_last_day, :held => 1})

      @statistics << statistic

      t_first_day = t_last_day.+1.seconds
      t_last_day = t_first_day.+1.months.-1.seconds

      break if t_first_day > t_now
    end

    @statistics
  end

end
