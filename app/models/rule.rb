# frozen_string_literal: true

# Sender25 - Added model for rules
# == Schema Information
#
# Table name: rules
#
#  id         :integer          not null, primary key
#  uuid       :string(255)
#  owner_type :string(255)
#  owner_id   :integer
#  from_text  :text(65535)
#  to_text    :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Rule < ApplicationRecord

  include HasUUID

  belongs_to :owner, polymorphic: true
  has_many :rule_ip_pools, dependent: :destroy
  has_many :ip_pools, through: :rule_ip_pools

  validate :validate_from_and_to_addresses
  # validate :validate_ip_pool_belongs_to_organization

  def from
    from_text ? from_text.gsub(/\r/, '').split(/\n/).map(&:strip) : []
  end

  def to
    to_text ? to_text.gsub(/\r/, '').split(/\n/).map(&:strip) : []
  end

  def apply_to_message?(message)
    if from.present? && message.headers['from'].present?
      from.each do |condition|
        if message.headers['from'].any? { |f| self.class.address_matches?(condition.downcase, f) }
          return true
        end
      end
    end

    if to.present? && message.rcpt_to.present?
      address = Postal::Helpers.strip_name_from_address(message.rcpt_to)
      mx_servers = Postal::Helpers.return_mx_lookup(address.split('@').last)

      to.each do |condition|
        if self.class.address_matches_mx?(condition.downcase, mx_servers)
          return true
        end
      end

      to.each do |condition|
        if self.class.address_matches?(condition.downcase, message.rcpt_to)
          return true
        end
      end
    end

    false
  end

  private

  def validate_from_and_to_addresses
    if self.from.empty? && self.to.empty?
      errors.add :base, "At least one rule condition must be specified"
    end
  end

  def validate_ip_pool_belongs_to_organization
    org = self.owner.is_a?(Organization) ? self.owner : self.owner.organization
    if self.ip_pool && self.ip_pool_id_changed? && !org.ip_pools.include?(self.ip_pool)
      errors.add :ip_pool_id, "must belong to the organization"
    end
  end

  def self.address_matches?(condition, address)
    address = Postal::Helpers.strip_name_from_address(address)
    return false if address.nil?
    if condition =~ /@/
      parts = address.split('@')
      domain, uname = parts.pop, parts.join('@')
      uname, _ = uname.split('+', 2)
      condition == "#{uname}@#{domain}"
    else
      # Match as a domain
      condition == address.split('@').last
    end
  end

  def self.address_matches_mx?(condition, mx_servers)
    if condition !~ /@/
      mx_servers.each do |hostname|
        return true if hostname.end_with?(condition)
      end
    end
    false
  end

end
