# frozen_string_literal: true

# Sender25 - Added controller for create and delete domain
controller :domain do
  friendly_name "Create Domain API" 
  description "This API allows you to send messages"
  authenticator :server

  action :new do
    title "Create Domain"
    description "This action allows you to send a message by providing the appropriate options"
    param :name, "The e-mail addresses of the recipients (max 50)", type: String
    param :dkim_private_key, type: String
    returns Hash
    action do
      attributes = {}
      attributes[:name] = params.name
      attributes[:owner_id] = identity.server_id
      attributes[:owner_type] = "Server"

      domain = Domain.find_by(attributes)

      attributes[:dkim_private_key] = params.dkim_private_key
      attributes[:dkim_status] = "Missing"
      attributes[:verification_method] = "DNS"
      attributes[:verified_at] = Time.now

      if domain.nil?
        domain = Domain.create(attributes)
        ip = Rule.find_by(owner_id: identity.server_id)
        if ip.nil?
          Rule.create({ owner_id: identity.server_id, from_text: params.name, owner_type: "Server" })
        else
          Rule.update(ip.id, from_text: "#{ip.from_text}\r\n#{params.name}")
        end
      else
        Domain.update(domain.id, dkim_private_key: attributes[:dkim_private_key], dkim_status: attributes[:dkim_status], verified_at: attributes[:verified_at])
      end
      domain.check_dns
    end
  end

  action :delete do
    title "Delete Domain"
    description "Delete domain"
    param :name, "Domain name to be deleted", type: String
    returns Hash
    action do
      attributes = {}
      attributes[:name] = params.name
      attributes[:owner_id] = identity.server_id
      attributes[:owner_type] = "Server"

      domain = Domain.find_by(attributes)
      domain&.destroy

      ip = Rule.find_by(owner_id: identity.server_id)
      unless ip.nil?
        from = ip.from_text.gsub("#{params.name}\r\n", '')
        Rule.update(ip.id, from_text: from)
      end
    end
  end
end
