# frozen_string_literal: true

if Sender25::Config.rails.secret_key
  Rails.application.secrets.secret_key_base = Sender25::Config.rails.secret_key
else
  warn "No secret key was specified in the Sender25 config file. Using one for just this session"
  Rails.application.secrets.secret_key_base = SecureRandom.hex(128)
end
