# frozen_string_literal: true

module Postal
  class BounceMessage

    def initialize(server, message)
      @server = server
      @message = message
    end

    def raw_message
      mail = Mail.new
      mail.to = @message.mail_from
      # Sender25 - Changed to postmaster_address
      mail.from = "Mail Delivery Service <#{postmaster_address}>"
      mail.subject = "Mail Delivery Failed (#{@message.subject})"
      mail.text_part = body
      mail.attachments["Original Message.eml"] = { mime_type: "message/rfc822", encoding: "quoted-printable", content: @message.raw_message }
      mail.message_id = "<#{SecureRandom.uuid}@#{Postal.config.dns.return_path}>"
      mail.to_s
    end

    def queue
      message = @server.message_db.new_message
      message.scope = "outgoing"
      message.rcpt_to = @message.mail_from
      # Sender25 - Changed to postmaster_address
      message.mail_from = postmaster_address
      message.domain_id = @message.domain&.id
      message.raw_message = raw_message
      message.bounce = true
      message.bounce_for_id = @message.id
      message.save
      message.id
    end

    def postmaster_address
      # Sender25 - New search for postmaster
      if !@message.mail_from.nil? && !@message.mail_from.empty?
        mx_servers = Postal::Helpers.return_mx_lookup(@message.mail_from.split('@').last)

        mx_servers.each do |hostname|
          if hostname.end_with?('spfbl.net')
            return "postmaster@#{@message.domain&.name}" if @message.domain&.name
            return @server.postmaster_address if @server.postmaster_address
          end
        end
      end
      @server.postmaster_address || "postmaster@#{@message.domain&.name || Postal.config.web.host}"
    end

    private

    # Sender25 - Changed route description to rcpt_to
    def body
      <<~BODY
        This is the mail delivery service responsible for delivering mail to #{@message.rcpt_to}.

        The message you've sent cannot be delivered. Your original message is attached to this message.

        For further assistance please contact #{postmaster_address}. Please include the details below to help us identify the issue.

        Message Token: #{@message.token}@#{@server.token}
        Orginal Message ID: #{@message.message_id}
        Mail from: #{@message.mail_from}
        Rcpt To: #{@message.rcpt_to}
      BODY
    end

  end
end
