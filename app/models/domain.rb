# frozen_string_literal: true

# == Schema Information
#
# Table name: domains
#
#  id                  :integer          not null, primary key
#  custom_dkim_key     :boolean          default(FALSE), not null
#  dkim_error          :string(255)
#  dkim_private_key    :text(65535)
#  dkim_status         :string(255)
#  dns_checked_at      :datetime
#  incoming            :boolean          default(TRUE)
#  mx_error            :string(255)
#  mx_status           :string(255)
#  name                :string(255)
#  outgoing            :boolean          default(TRUE)
#  owner_type          :string(255)
#  return_path_error   :string(255)
#  return_path_status  :string(255)
#  spf_error           :string(255)
#  spf_status          :string(255)
#  use_for_any         :boolean
#  uuid                :string(255)
#  verification_method :string(255)
#  verification_token  :string(255)
#  verified_at         :datetime
#  created_at          :datetime
#  updated_at          :datetime
#  owner_id            :integer
#  server_id           :integer
#
# Indexes
#
#  index_domains_on_server_id  (server_id)
#  index_domains_on_uuid       (uuid)
#

require "resolv"

class Domain < ApplicationRecord

  include HasUUID

  include HasDNSChecks

  VERIFICATION_EMAIL_ALIASES = %w[webmaster postmaster admin administrator hostmaster].freeze
  VERIFICATION_METHODS = %w[DNS Email].freeze

  belongs_to :server, optional: true
  belongs_to :owner, optional: true, polymorphic: true
  has_many :routes, dependent: :destroy
  has_many :track_domains, dependent: :destroy

  validates :name, presence: true, format: { with: /\A[a-z0-9\-.]*\z/ }, uniqueness: { case_sensitive: false, scope: [:owner_type, :owner_id], message: "is already added" }
  validates :verification_method, inclusion: { in: VERIFICATION_METHODS }
  validate :validate_dkim_private_key, if: :dkim_private_key_changed?

  before_create :generate_dkim_key

  scope :verified, -> { where.not(verified_at: nil) }

  before_save :update_verification_token_on_method_change

  def verified?
    verified_at.present?
  end

  def mark_as_verified
    return false if verified?

    self.verified_at = Time.now
    save!
  end

  def parent_domains
    parts = name.split(".")
    parts[0, parts.size - 1].each_with_index.map do |_, i|
      parts[i..].join(".")
    end
  end

  def generate_dkim_key
    self.dkim_private_key = OpenSSL::PKey::RSA.new(1024).to_s
    self.custom_dkim_key = false
  end

  def dkim_key
    return nil unless dkim_private_key

    @dkim_key ||= OpenSSL::PKey::RSA.new(dkim_private_key)
  end

  def to_param
    uuid
  end

  def verification_email_addresses
    parent_domains.map do |domain|
      VERIFICATION_EMAIL_ALIASES.map do |a|
        "#{a}@#{domain}"
      end
    end.flatten
  end

  def spf_record
    "v=spf1 a mx include:#{Sender25::Config.dns.spf_include} ~all"
  end

  def dkim_record
    return if dkim_key.nil?

    public_key = dkim_key.public_key.to_s.gsub(/-+[A-Z ]+-+\n/, "").gsub(/\n/, "")
    
    # Use generic format for custom keys, default format for auto-generated keys
    if custom_dkim_key?
      "v=DKIM1; k=rsa; p=#{public_key};"
    else
      "v=DKIM1; t=s; h=sha256; p=#{public_key};"
    end
  end

  def dkim_identifier
    # Return just the configured identifier
    Sender25::Config.dns.dkim_identifier
  end

  def dkim_record_name
    identifier = dkim_identifier
    return if identifier.nil?

    "#{identifier}._domainkey"
  end

  def return_path_domain
    "#{Sender25::Config.dns.custom_return_path_prefix}.#{name}"
  end

  # Returns a DNSResolver instance that can be used to perform DNS lookups needed for
  # the verification and DNS checking for this domain.
  #
  # @return [DNSResolver]
  def resolver
    return DNSResolver.local if Sender25::Config.sender25.use_local_ns_for_domain_verification?

    @resolver ||= DNSResolver.for_domain(name)
  end

  def dns_verification_string
    "#{Sender25::Config.dns.domain_verify_prefix} #{verification_token}"
  end

  def verify_with_dns
    return false unless verification_method == "DNS"

    result = resolver.txt(name)

    if result.include?(dns_verification_string)
      self.verified_at = Time.now
      return save
    end

    false
  end

  private

  def update_verification_token_on_method_change
    return unless verification_method_changed?

    if verification_method == "DNS"
      self.verification_token = SecureRandom.alphanumeric(32)
    elsif verification_method == "Email"
      self.verification_token = rand(999_999).to_s.ljust(6, "0")
    else
      self.verification_token = nil
    end
  end

  def validate_dkim_private_key
    return if dkim_private_key.blank?
    
    begin
      OpenSSL::PKey::RSA.new(dkim_private_key)
    rescue OpenSSL::PKey::RSAError => e
      errors.add(:dkim_private_key, "is not a valid RSA private key: #{e.message}")
    end
  end

end
