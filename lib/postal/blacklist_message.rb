# frozen_string_literal: true

# Sender25 - Added default message for blacklist notification
module Postal

  class BlacklistMessage

    def initialize(server, message, ip, error)
      @server = server
      @message = message
      @ip = ip
      @error = error
    end

    def raw_message
      mail = Mail.new
      mail.to = "suporte@gk2.com.br"
      mail.from = "Blacklist detected <#{postmaster_address}>"
      mail.subject = "IP <#{@ip&.ipv4} #{@ip&.ipv6}> listed in blacklist"
      mail.text_part = body
      mail.message_id = "<#{SecureRandom.uuid}@#{Postal.config.dns.return_path}>"
      mail.to_s
    end

    def queue
      message = @server.message_db.new_message
      message.scope = "outgoing"
      message.rcpt_to = "suporte@gk2.com.br"
      message.mail_from = postmaster_address
      message.domain_id = @message.domain&.id
      message.raw_message = self.raw_message
      message.bounce = 0
      message.save
      message.id
    end

    def postmaster_address
      @server.postmaster_address || "postmaster@#{@message.domain&.name || Postal.config.web.host}"
    end

    private

    def body
      <<~BODY
        This is the mail delivery service responsible for delivering mail to #{@message.rcpt_to}.

        The ip address <#{@ip&.ipv4} #{@ip&.ipv6}> used from sending is blacklist listed.

        Error returned: #{@error}

        Message Token: #{@message.token}@#{@server.token}
        Original Server: #{@server.name}
        Original Message ID: #{@message.message_id}
        Mail from: #{@message.mail_from}
        Rcpt To: #{@message.rcpt_to}
      BODY
    end

  end
end

