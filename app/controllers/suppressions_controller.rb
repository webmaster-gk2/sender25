# frozen_string_literal: true

# Sender25 - Added controller for global suppression list
class SuppressionsController < ApplicationController

  before_action :admin_required, only: [:index]
  before_action { @organization = Organization.present.first }
  before_action { @server = @organization.servers.present.first }

  def index
    @suppressions = @server.message_db.suppression_list.all_with_pagination(params[:page])
  end

end
