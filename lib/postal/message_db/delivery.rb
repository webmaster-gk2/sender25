# frozen_string_literal: true

module Postal
  module MessageDB
    class Delivery

      def self.create(message, attributes = {})
        attributes = message.database.stringify_keys(attributes)
        attributes = attributes.merge("message_id" => message.id, "timestamp" => Time.now.to_f)

        # Ensure that output and details don't overflow their columns. We don't need
        # these values to store more than 250 characters.
        attributes["output"] = attributes["output"][0, 250] if attributes["output"]
        attributes["details"] = attributes["details"][0, 250] if attributes["details"]

        id = message.database.insert("deliveries", attributes)

        delivery = Delivery.new(message, attributes.merge("id" => id))
        delivery.update_statistics
        delivery.send_webhooks
        delivery
      end

      def initialize(message, attributes)
        @message = message
        @attributes = attributes.stringify_keys
      end

      def method_missing(name, value = nil, &block)
        return unless @attributes.key?(name.to_s)

        @attributes[name.to_s]
      end

      def respond_to_missing?(name, include_private = false)
        @attributes.key?(name.to_s)
      end

      def timestamp
        @timestamp ||= @attributes["timestamp"] ? Time.zone.at(@attributes["timestamp"]) : nil
      end

      def update_statistics
        if status == "Held"
          @message.database.statistics.increment_all(timestamp, "held")
        end

        return unless status == "Bounced" || status == "HardFail"

        @message.database.statistics.increment_all(timestamp, "bounces")
      end

      def send_webhooks
        return unless webhook_event

        WebhookRequest.trigger(@message.database.server_id, webhook_event, webhook_hash)
      end

      def webhook_hash
        {
          message: @message.webhook_hash,
          status: status,
          details: details,
          output: output.to_s.dup.force_encoding("UTF-8").scrub.truncate(512),
          sent_with_ssl: sent_with_ssl,
          timestamp: @attributes["timestamp"],
          time: time
        }
      end

      # rubocop:disable Style/HashLikeCase
      def webhook_event
        @webhook_event ||= case status
                           when "Sent" then "MessageSent"
                           when "SoftFail" then "MessageDelayed"
                           when "HardFail" then "MessageDeliveryFailed"
                           when "Held" then "MessageHeld"
                           end
      end
      # rubocop:enable Style/HashLikeCase

    end
  end
end
