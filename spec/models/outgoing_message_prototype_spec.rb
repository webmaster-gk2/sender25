# frozen_string_literal: true

require "rails_helper"

describe OutgoingMessagePrototype do
  let(:server) { create(:server) }
  it "should create a new message" do
    domain = create(:domain, owner: server)
    prototype = OutgoingMessagePrototype.new(server, "127.0.0.1", "TestSuite", {
      from: "test@#{domain.name}",
      to: "test@example.com",
      subject: "Test Message",
      plain_body: "A plain body!"
    })

    expect(prototype.valid?).to be true
    message = prototype.create_message("test@example.com")
    expect(message).to be_a Hash
    expect(message[:id]).to be_a Integer
    expect(message[:token]).to be_a String
  end
end
