# frozen_string_literal: true

config = Sender25::Config.oidc
if config.enabled?
  client_options = { identifier: config.identifier, secret: config.secret }

  client_options[:redirect_uri] = "#{Sender25::Config.sender25.web_protocol}://#{Sender25::Config.sender25.web_hostname}/auth/oidc/callback"

  unless config.discovery?
    client_options[:authorization_endpoint] = config.authorization_endpoint
    client_options[:token_endpoint] = config.token_endpoint
    client_options[:userinfo_endpoint] = config.userinfo_endpoint
    client_options[:jwks_uri] = config.jwks_uri
  end

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :openid_connect, name: :oidc,
                              scope: config.scopes.map(&:to_sym),
                              uid_field: config.uid_field,
                              issuer: config.issuer,
                              discovery: config.discovery?,
                              client_options: client_options
  end

  OmniAuth.config.on_failure = proc do |env|
    SessionsController.action(:oauth_failure).call(env)
  end
end
