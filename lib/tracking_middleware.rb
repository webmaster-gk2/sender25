# frozen_string_literal: true

class TrackingMiddleware

  TRACKING_PIXEL = File.read(Rails.root.join("app", "assets", "images", "tracking_pixel.png"))

  def initialize(app = nil)
    @app = app
  end

  def call(env)
    unless env["HTTP_X_POSTAL_TRACK_HOST"].to_i == 1
      return @app.call(env)
    end

    request = Rack::Request.new(env)

    case request.path
    when /\A\/img\/([a-z0-9-]+)\/([a-z0-9-]+)/i
      server_token = ::Regexp.last_match(1)
      message_token = ::Regexp.last_match(2)
      dispatch_image_request(request, server_token, message_token)
    when /\A\/([a-z0-9-]+)\/([a-z0-9-]+)/i
      server_token = ::Regexp.last_match(1)
      link_token = ::Regexp.last_match(2)
      dispatch_redirect_request(request, server_token, link_token)
    else
      [200, {}, ["Hello."]]
    end
  end

  private

  def dispatch_image_request(request, server_token, message_token)
    message_db = get_message_db_from_server_token(server_token)
    if message_db.nil?
      return [404, {}, ["Invalid Server Token"]]
    end

    begin
      message = message_db.message(token: message_token)
      message.create_load(request)
    rescue Postal::MessageDB::Message::NotFound
      # This message has been removed, we'll just continue to serve the image
    rescue StandardError => e
      # Somethign else went wrong. We don't want to stop the image loading though because
      # this is our problem. Log this exception though.
      Sentry.capture_exception(e) if defined?(Sentry)
    end

    source_image = request.params["src"]
    case source_image
    when nil
      headers = {}
      headers["Content-Type"] = "image/png"
      headers["Content-Length"] = TRACKING_PIXEL.bytesize.to_s
      [200, headers, [TRACKING_PIXEL]]
    when /\Ahttps?:\/\//
      response = Postal::HTTP.get(source_image, timeout: 3)
      return [404, {}, ["Not found"]] unless response[:code] == 200

      headers = {}
      headers["Content-Type"] = response[:headers]["content-type"]&.first
      headers["Last-Modified"] = response[:headers]["last-modified"]&.first
      headers["Cache-Control"] = response[:headers]["cache-control"]&.first
      headers["Etag"] = response[:headers]["etag"]&.first
      headers["Content-Length"] = response[:body].bytesize.to_s
      [200, headers, [response[:body]]]

    else
      [400, {}, ["Invalid/missing source image"]]
    end
  end

  def dispatch_redirect_request(request, server_token, link_token)
    message_db = get_message_db_from_server_token(server_token)
    if message_db.nil?
      return [404, {}, ["Invalid Server Token"]]
    end

    link = message_db.select(:links, where: { token: link_token }, limit: 1).first
    if link.nil?
      return [404, {}, ["Link not found"]]
    end

    time = Time.now.to_f
    if link["message_id"]
      message_db.update(:messages, { clicked: time }, where: { id: link["message_id"] })
      message_db.insert(:clicks, {
        message_id: link["message_id"],
        link_id: link["id"],
        ip_address: request.ip,
        user_agent: request.user_agent,
        timestamp: time
      })

      begin
        message_webhook_hash = message_db.message(link["message_id"]).webhook_hash
        WebhookRequest.trigger(message_db.server, "MessageLinkClicked", {
          message: message_webhook_hash,
          url: link["url"],
          token: link["token"],
          ip_address: request.ip,
          user_agent: request.user_agent
        })
      rescue Postal::MessageDB::Message::NotFound
        # If we can't find the message that this link is associated with, we'll just ignore it
        # and not trigger any webhooks.
      end
    end

    [307, { "Location" => link["url"] }, ["Redirected to: #{link['url']}"]]
  end

  def get_message_db_from_server_token(token)
    return unless server = ::Server.find_by_token(token)

    server.message_db
  end

end
