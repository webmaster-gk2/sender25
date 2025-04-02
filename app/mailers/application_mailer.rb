# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base

  default from: "#{Sender25::Config.smtp.from_name} <#{Sender25::Config.smtp.from_address}>"
  layout false

end
