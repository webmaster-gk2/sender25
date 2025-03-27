# frozen_string_literal: true

class AppMailer < ApplicationMailer

  def verify_email_address(user)
    @user = user
    mail to: @user.email_address, subject: "Verify your new e-mail address"
  end

  def new_user(user)
    @user = user
    # Sender25 - Change "Postal" to "Sender25"
    mail to: @user.email_address, subject: "Welcome to Sender25"
  end

  def user_invite(user_invite, organization)
    @user_invite = user_invite
    @organization = organization
    # Sender25 - Change "Postal" to "Sender25"
    mail to: @user_invite.email_address, subject: "Access the #{organization.name} organization on Sender25"
  end

  def verify_domain(domain, email_address, user)
    @domain = domain
    @email_address = email_address
    @user = user
    mail to: email_address, subject: "Verify your ownership of #{@domain.name}"
  end

  def password_reset(user, return_to = nil)
    @user = user
    @return_to = return_to
    # Sender25 - Change "Postal" to "Sender25"
    mail to: @user.email_address, subject: "Reset your Sender25 password"
  end

  def server_send_limit_approaching(server)
    @server = server
    mail to: @server.organization.notification_addresses, subject: "[#{server.full_permalink}] Mail server is approaching its send limit"
  end

  def server_send_limit_exceeded(server)
    @server = server
    mail to: @server.organization.notification_addresses, subject: "[#{server.full_permalink}] Mail server has exceeded its send limit"
  end

  def server_suspended(server)
    @server = server
    mail to: @server.organization.notification_addresses, subject: "[#{server.full_permalink}] Your mail server has been suspended"
  end

  def test_message(recipient)
    # Sender25 - Change "Postal" to "Sender25"
    mail to: recipient, subject: "Sender25 SMTP Test Message"
  end

end
