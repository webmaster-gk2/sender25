# frozen_string_literal: true

class CheckAllDNSScheduledTask < ApplicationScheduledTask

  def call
    Domain.where.not(dns_checked_at: nil).where("dns_checked_at <= ?", 1.hour.ago).each do |domain|
      logger.info "checking DNS for domain: #{domain.name}"
      domain.check_dns(:auto)
    end

    TrackDomain.where("dns_checked_at IS NULL OR dns_checked_at <= ?", 1.hour.ago).includes(:domain).each do |domain|
      logger.info "checking DNS for track domain: #{domain.full_name}"
      domain.check_dns
    end
  end

end
