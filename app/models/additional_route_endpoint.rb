# frozen_string_literal: true

# == Schema Information
#
# Table name: additional_route_endpoints
#
#  id            :integer          not null, primary key
#  route_id      :integer
#  endpoint_type :string(255)
#  endpoint_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class AdditionalRouteEndpoint < ApplicationRecord

  belongs_to :route
  belongs_to :endpoint, polymorphic: true

  validate :validate_endpoint_belongs_to_server
  validate :validate_wildcard
  validate :validate_uniqueness

  def self.find_by_endpoint(endpoint)
    class_name, id = endpoint.split("#", 2)
    unless Route::ENDPOINT_TYPES.include?(class_name)
      raise Postal::Error, "Invalid endpoint class name '#{class_name}'"
    end

    return unless uuid = class_name.constantize.find_by_uuid(id)

    where(endpoint_type: class_name, endpoint_id: uuid).first
  end

  def _endpoint
    "#{endpoint_type}##{endpoint.uuid}"
  end

  def _endpoint=(value)
    if value && value =~ /\#/
      class_name, id = value.split("#", 2)
      unless Route::ENDPOINT_TYPES.include?(class_name)
        raise Postal::Error, "Invalid endpoint class name '#{class_name}'"
      end

      self.endpoint = class_name.constantize.find_by_uuid(id)
    else
      self.endpoint = nil
    end
  end

  private

  def validate_endpoint_belongs_to_server
    return unless endpoint && endpoint&.server != route.server

    errors.add :endpoint, :invalid
  end

  def validate_uniqueness
    return unless endpoint == route.endpoint

    errors.add :base, "You can only add an endpoint to a route once"
  end

  def validate_wildcard
    return unless route.wildcard?
    return unless endpoint_type == "SMTPEndpoint" || endpoint_type == "AddressEndpoint"

    errors.add :base, "SMTP or address endpoints are not permitted on wildcard routes"
  end

end
