# frozen_string_literal: true

module Sender25
  class MessageInspector

    def initialize(config)
      @config = config
    end

    # Inspect a message and update the inspection with the results
    # as appropriate.
    def inspect_message(message, scope, inspection)
    end

    private

    def logger
      Sender25.logger
    end

    class << self

      # Return an array of all inspectors that are available for this
      # installation.
      def inspectors
        [].tap do |inspectors|
          if Sender25::Config.rspamd.enabled?
            inspectors << MessageInspectors::Rspamd.new(Sender25::Config.rspamd)
          elsif Sender25::Config.spamd.enabled?
            inspectors << MessageInspectors::SpamAssassin.new(Sender25::Config.spamd)
          end

          if Sender25::Config.clamav.enabled?
            inspectors << MessageInspectors::Clamav.new(Sender25::Config.clamav)
          end
        end
      end

    end

  end
end
