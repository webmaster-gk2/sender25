# frozen_string_literal: true

# Sender25 - Added model for RuleIPPool
# == Schema Information
#
# Table name: rule_ip_pools
#
#  id         :integer          not null, primary key
#  uuid       :string(255)
#  rule_id    :integer
#  ip_pool_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class RuleIPPool < ApplicationRecord
  belongs_to :rule
  belongs_to :ip_pool

  # validate :validate_ip_pool_belongs_to_organization

  def validate_ip_pool_belongs_to_organization
    org = self.rule.owner.is_a?(Organization) ? self.rule.owner : self.rule.owner.organization
    if self.ip_pool && self.ip_pool_id_changed? && !org.ip_pools.include?(self.ip_pool)
      errors.add :ip_pool_id, "must belong to the organization"
    end
  end
end
