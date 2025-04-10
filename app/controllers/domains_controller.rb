# frozen_string_literal: true

class DomainsController < ApplicationController

  include WithinOrganization

  before_action do
    if params[:server_id]
      @server = organization.servers.present.find_by_permalink!(params[:server_id])
      if params[:id]
        @domain = @server.domains.find_by_uuid!(params[:id])
      end
    else
      if params[:id]
        @domain = organization.domains.find_by_uuid!(params[:id])
      end
    end
  end

  def index
    if params[:server_id]
        @server = organization.servers.find_by_permalink!(params[:server_id])
        @domains = @server.domains.order(:name)
    else
        @domains = organization.domains.order(:name)
    end
  
    respond_to do |format|
        format.html  # renders the default view
        format.json do
          render json: @domains.as_json(only: [
            :uuid, :name,
            :spf_status, :spf_error,
            :dkim_status, :dkim_error,
            :mx_status, :mx_error,
            :return_path_status, :return_path_error
          ])
        end
    end
  end

  def new
    @domain = @server ? @server.domains.build : organization.domains.build
  end

  def create
    scope = @server ? @server.domains : organization.domains
    @domain = scope.build(params.require(:domain).permit(:name, :verification_method))

    if current_user.admin?
      @domain.verification_method = "DNS"
      @domain.verified_at = Time.now
    end

    if @domain.save
      if @domain.verified?
        redirect_to_with_json [:setup, organization, @server, @domain]
      else
        redirect_to_with_json [:verify, organization, @server, @domain]
      end
    else
      render_form_errors "new", @domain
    end
  end

  def destroy
    @domain.destroy
    redirect_to_with_json [organization, @server, :domains]
  end

  def verify
    if @domain.verified?
      redirect_to [organization, @server, :domains], alert: "#{@domain.name} has already been verified."
      return
    end

    return unless request.post?

    case @domain.verification_method
    when "DNS"
      if @domain.verify_with_dns
        redirect_to_with_json [:setup, organization, @server, @domain], notice: "#{@domain.name} has been verified successfully. You now need to configure your DNS records."
      else
        respond_to do |wants|
          wants.html { flash.now[:alert] = "We couldn't verify your domain. Please double check you've added the TXT record correctly." }
          wants.json { render json: { flash: { alert: "We couldn't verify your domain. Please double check you've added the TXT record correctly." } } }
        end
      end
    when "Email"
      if params[:code]
        if @domain.verification_token == params[:code].to_s.strip
          @domain.mark_as_verified
          redirect_to_with_json [:setup, organization, @server, @domain], notice: "#{@domain.name} has been verified successfully. You now need to configure your DNS records."
        else
          respond_to do |wants|
            wants.html { flash.now[:alert] = "Invalid verification code. Please check and try again." }
            wants.json { render json: { flash: { alert: "Invalid verification code. Please check and try again." } } }
          end
        end
      elsif params[:email_address].present?
        raise Sender25::Error, "Invalid email address" unless @domain.verification_email_addresses.include?(params[:email_address])

        AppMailer.verify_domain(@domain, params[:email_address], current_user).deliver
        if @domain.owner.is_a?(Server)
          redirect_to_with_json verify_organization_server_domain_path(organization, @server, @domain, email_address: params[:email_address])
        else
          redirect_to_with_json verify_organization_domain_path(organization, @domain, email_address: params[:email_address])
        end
      end
    end
  end

  def setup
    return if @domain.verified?

    redirect_to [:verify, organization, @server, @domain], alert: "You can't set up DNS for this domain until it has been verified."
  end

  def check
    if @domain.check_dns(:manual)
      redirect_to_with_json [organization, @server, :domains], notice: "Your DNS records for #{@domain.name} look good!"
    else
      redirect_to_with_json [:setup, organization, @server, @domain], alert: "There seems to be something wrong with your DNS records. Check below for information."
    end
  end

  def update_dkim_key
    if params[:dkim_private_key].present?
      begin
        # Validate the key is a valid RSA private key
        key = OpenSSL::PKey::RSA.new(params[:dkim_private_key])
        
        # Update the key and mark it as custom
        @domain.dkim_private_key = params[:dkim_private_key]
        @domain.custom_dkim_key = true
        
        if @domain.save
          # Reload the domain to ensure changes are reflected
          @domain.reload
          
          # Trigger DNS check to verify the DKIM record
          @domain.check_dkim_record!
          
          redirect_to_with_json [:setup, organization, @server, @domain], notice: "DKIM key updated successfully"
        else
          render_form_errors "setup", @domain
        end
      rescue OpenSSL::PKey::RSAError => e
        redirect_to_with_json [:setup, organization, @server, @domain], alert: "Invalid RSA private key: #{e.message}"
      end
    else
      redirect_to_with_json [:setup, organization, @server, @domain], alert: "No DKIM key provided"
    end
  end

end
