# frozen_string_literal: true

# Sender25 - Controller to manipulate the new rules of rules
class RulesController < ApplicationController

  include WithinOrganization

  before_action do
    if params[:server_id]
      @server = organization.servers.present.find_by_permalink!(params[:server_id])
      params[:id] && @rule = @server.rules.find_by_uuid!(params[:id])
    else
      params[:id] && @rule = organization.rules.find_by_uuid!(params[:id])
    end
  end

  def index
    if @server
      @rules = @server.rules
    else
      @rules = organization.rules
    end
  end

  def new
    @rule = @server ? @server.rules.build : organization.rules.build
  end

  def create
    scope = @server ? @server.rules : organization.rules
    @rule = scope.build(safe_params)
    if @rule.save
      @rule.ip_pool_ids = params[:ip_pools]
      @rule.save!
      redirect_to_with_json [organization, @server, :rules]
    else
      render_form_errors 'new', @rule
    end
  end

  def update
    if @rule.update(safe_params)
      @rule.ip_pool_ids = params[:ip_pools]
      @rule.save!
      redirect_to_with_json [organization, @server, :rules]
    else
      render_form_errors 'edit', @rule
    end
  end

  def destroy
    @rule.destroy
    redirect_to_with_json [organization, @server, :rules]
  end

  private

  def safe_params
    params.require(:rule).permit(:from_text, :to_text)
  end

end
