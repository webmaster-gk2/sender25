# frozen_string_literal: true

require "resolv"

class OutgoingMessagePrototype

  attr_accessor :from
  attr_accessor :sender
  attr_accessor :to
  attr_accessor :cc
  attr_accessor :bcc
  attr_accessor :subject
  attr_accessor :reply_to
  attr_accessor :custom_headers
  attr_accessor :plain_body
  attr_accessor :html_body
  attr_accessor :attachments
  attr_accessor :tag
  attr_accessor :credential
  attr_accessor :bounce

  def initialize(server, ip, source_type, attributes)
    @server = server
    @ip = ip
    @source_type = source_type
    @custom_headers = {}
    @attachments = []
    @message_id = "#{SecureRandom.uuid}@#{Postal::Config.dns.return_path_domain}"
    attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  attr_reader :message_id

  def from_address
    Postal::Helpers.strip_name_from_address(@from)
  end

  def sender_address
    Postal::Helpers.strip_name_from_address(@sender)
  end

  def domain
    @domain ||= begin
      d = find_domain
      d == :none ? nil : d
    end
  end

  def find_domain
    domain = @server.authenticated_domain_for_address(@from)
    if @server.allow_sender? && domain.nil?
      domain = @server.authenticated_domain_for_address(@sender)
    end
    domain || :none
  end

  def to_addresses
    @to.is_a?(String) ? @to.to_s.split(/,\s*/) : @to.to_a
  end

  def cc_addresses
    @cc.is_a?(String) ? @cc.to_s.split(/,\s*/) : @cc.to_a
  end

  def bcc_addresses
    @bcc.is_a?(String) ? @bcc.to_s.split(/,\s*/) : @bcc.to_a
  end

  def all_addresses
    [to_addresses, cc_addresses, bcc_addresses].flatten
  end

  def create_messages
    if valid?
      all_addresses.each_with_object({}) do |address, hash|
        if address = Postal::Helpers.strip_name_from_address(address)
          hash[address] = create_message(address)
        end
      end
    else
      false
    end
  end

  def valid?
    validate
    errors.empty?
  end

  def errors
    @errors || {}
  end

  # rubocop:disable Lint/DuplicateMethods
  def attachments
    (@attachments || []).map do |attachment|
      {
        name: attachment[:name],
        content_type: attachment[:content_type] || "application/octet-stream",
        data: attachment[:base64] && attachment[:data] ? Base64.decode64(attachment[:data]) : attachment[:data]
      }
    end
  end
  # rubocop:enable Lint/DuplicateMethods

  def validate
    @errors = []

    if to_addresses.empty? && cc_addresses.empty? && bcc_addresses.empty?
      @errors << "NoRecipients"
    end

    if to_addresses.size > 50
      @errors << "TooManyToAddresses"
    end

    if cc_addresses.size > 50
      @errors << "TooManyCCAddresses"
    end

    if bcc_addresses.size > 50
      @errors << "TooManyBCCAddresses"
    end

    if @plain_body.blank? && @html_body.blank?
      @errors << "NoContent"
    end

    if from.blank?
      @errors << "FromAddressMissing"
    end

    if domain.nil?
      @errors << "UnauthenticatedFromAddress"
    end

    if attachments.present?
      attachments.each do |attachment|
        if attachment[:name].blank?
          @errors << "AttachmentMissingName" unless @errors.include?("AttachmentMissingName")
        elsif attachment[:data].blank?
          @errors << "AttachmentMissingData" unless @errors.include?("AttachmentMissingData")
        end
      end
    end
    @errors
  end

  def raw_message
    @raw_message ||= begin
      mail = Mail.new
      if @custom_headers.is_a?(Hash)
        @custom_headers.each { |key, value| mail[key.to_s] = value.to_s }
      end
      mail.to = to_addresses.join(", ") if to_addresses.present?
      mail.cc = cc_addresses.join(", ") if cc_addresses.present?
      mail.from = @from
      mail.sender = @sender
      mail.subject = @subject
      mail.reply_to = @reply_to
      mail.part content_type: "multipart/alternative" do |p|
        if @plain_body.present?
          p.text_part = Mail::Part.new
          p.text_part.body = @plain_body
        end
        if @html_body.present?
          p.html_part = Mail::Part.new
          p.html_part.content_type = "text/html; charset=UTF-8"
          p.html_part.body = @html_body
        end
      end
      attachments.each do |attachment|
        mail.attachments[attachment[:name]] = {
          mime_type: attachment[:content_type],
          content: attachment[:data]
        }
      end
      mail.header["Received"] = ReceivedHeader.generate(@server, @source_type, @ip, :http)
      mail.message_id = "<#{@message_id}>"
      mail.to_s
    end
  end

  def create_message(address)
    message = @server.message_db.new_message
    message.scope = "outgoing"
    message.rcpt_to = address
    message.mail_from = from_address
    message.domain_id = domain.id
    message.raw_message = raw_message
    message.tag = tag
    message.credential_id = credential&.id
    message.received_with_ssl = true
    message.bounce = @bounce
    message.save
    { id: message.id, token: message.token }
  end

end
