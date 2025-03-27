# frozen_string_literal: true

module Postal
  class MessageInspection

    attr_reader :message
    attr_reader :scope
    attr_reader :spam_checks
    attr_accessor :threat
    attr_accessor :threat_message

    # Sender25 - Added SPAM_EXCLUSIONS to filter spam checks
    SPAM_EXCLUSIONS = {
      :outgoing => ["NO_RECEIVED", "NO_RELAYS", "ALL_TRUSTED", "FREEMAIL_FORGED_REPLYTO", "RDNS_DYNAMIC", "CK_HELO_GENERIC", /^SPF\_/, /^HELO\_/, /DKIM_/, /^RCVD_IN_/],
      :incoming => []
    }

    # Sender25 - Added default value to scope and rescan
    def initialize(message, scope = :incoming, rescan = 0)
      ###
      # rescan = 0 -> initial inspection
      # rescan = 1 -> include in spam
      # rescan = 2 -> remove from spam
      ###

      @message = message
      @scope = scope
      @spam_checks = []
      @threat = false
      @spam_score = 0.0
      @error = false

      # Sender25 - Added rescan to initialize
      if Postal.config.spamd.enabled?
        rescan_for_spam(rescan) if rescan.positive?
        scan_for_spam if rescan.zero? || !error_detected
      end

      # Sender25 - Added clamav to initialize
      if Postal.config.clamav.enabled?
        scan_for_threats
      end
    end

    # Sender25 - Added error_detected to return error
    def error_detected
      @error
    end

    def spam_score
      return 0 if @spam_checks.empty?

      @spam_checks.sum(&:score)
    end

    # Sender25 - Added spam_checks to return all checks
    def spam_checks
      @spam_checks
    end

    # Sender25 - Added filtered_spam_checks to return checks without exclusions
    def filtered_spam_checks
      @filtered_spam_checks ||= @spam_checks.reject do |check|
        SPAM_EXCLUSIONS[@scope].any? do |item|
          item == check.code || (item.is_a?(Regexp) && item =~ check.code)
        end
      end
    end

    # Sender25 - Added filtered_spam_score to return score without exclusions
    def filtered_spam_score
      filtered_spam_checks.inject(0.0) do |total, check|
        total += check.score || 0.0
      end.round(2)
    end

    # Sender25 - Added threat?? to return if message is spam
    def threat?
      @threat == true
    end

    # Sender25 - Added threat_message to return message from clamav
    def threat_message
      @threat_message
    end

    def scan
      MessageInspector.inspectors.each do |inspector|
        inspector.inspect_message(self)
      end
    end

    class << self

      def scan(message, scope)
        inspection = new(message, scope)
        inspection.scan
        inspection
      end
    end

    private

    # Sender25 - Added rescan_for_spam to rescan for spam
    def rescan_for_spam(type)
      Timeout.timeout(15) do
        tcp_socket = TCPSocket.new(Postal.config.spamd.host, Postal.config.spamd.port)
        tcp_socket.write("TELL SPAMC/1.3\r\n")
        tcp_socket.write("Message-class: spam\r\n") if type == 1
        tcp_socket.write("Message-class: ham\r\n") if type == 2
        tcp_socket.write("Set: local\r\n")
        tcp_socket.write("Content-length: #{@message.bytesize}\r\n")
        tcp_socket.write("\r\n")
        tcp_socket.write(@message)
        tcp_socket.close_write
        tcp_socket.read
      end
    rescue Timeout::Error
      @error = true
      @spam_checks = [SPAMCheck.new("TIMEOUT", 0, "Timed out when scanning for spam")]
    rescue => e
      @error = true
      logger.error "Error talking to spamd: #{e.class} (#{e.message})"
      logger.error e.backtrace[0,5]
      @spam_checks = [SPAMCheck.new("ERROR", 0, "Error when scanning for spam")]
    ensure
      tcp_socket.close rescue nil
    end

    # Sender25 - Added scan_for_spam to scan for spam
    def scan_for_spam
      data = nil
      Timeout.timeout(15) do
        tcp_socket = TCPSocket.new(Postal.config.spamd.host, Postal.config.spamd.port)
        tcp_socket.write("REPORT SPAMC/1.2\r\n")
        tcp_socket.write("Content-length: #{@message.bytesize}\r\n")
        tcp_socket.write("\r\n")
        tcp_socket.write(@message)
        tcp_socket.close_write
        data = tcp_socket.read
      end

      spam_checks = []
      total = 0.0
      rules = data ? data.split(/^---(.*)\r?\n/).last.split(/\r?\n/) : []
      while line = rules.shift
        if line =~ /\A([\- ]?[\d\.]+)\s+(\w+)\s+(.*)/
          total += $1.to_f
          spam_checks << SPAMCheck.new($2, $1.to_f, $3)
        else
          spam_checks.last.description << " " + line.strip
        end
      end

      @spam_score = total.round(1)
      @spam_checks = spam_checks
    rescue Timeout::Error
      @error = true
      @spam_checks = [SPAMCheck.new("TIMEOUT", 0, "Timed out when scanning for spam")]
    rescue => e
      @error = true
      logger.error "Error talking to spamd: #{e.class} (#{e.message})"
      logger.error e.backtrace[0,5]
      @spam_checks = [SPAMCheck.new("ERROR", 0, "Error when scanning for spam")]
    ensure
      tcp_socket.close rescue nil
    end

    # Sender25 - Added scan_for_threats to scan for threats
    def scan_for_threats
      @threat = false

      data = nil
      Timeout.timeout(10) do
        tcp_socket = TCPSocket.new(Postal.config.clamav.host, Postal.config.clamav.port)
        tcp_socket.write("zINSTREAM\0")
        tcp_socket.write([@message.bytesize].pack("N"))
        tcp_socket.write(@message)
        tcp_socket.write([0].pack("N"))
        tcp_socket.close_write
        data = tcp_socket.read
      end

      if data && data =~ /\Astream\:\s+(.*?)[\s\0]+?/
        if $1.upcase == 'OK'
          @threat = false
          @threat_message = "No threats found"
        else
          @threat = true
          @threat_message = $1
        end
      else
        @threat = false
        @threat_message = "Could not scan message"
      end
    rescue Timeout::Error
      @threat = false
      @threat_message = "Timed out scanning for threats"
    rescue => e
      logger.error "Error talking to clamav: #{e.class} (#{e.message})"
      logger.error e.backtrace[0,5]
      @threat = false
      @threat_message = "Error when scanning for threats"
    ensure
      tcp_socket.close rescue nil
    end

    # Sender25 - Added logger to return logger
    def logger
      Postal.logger_for(:message_inspection)
    end

  end
end
