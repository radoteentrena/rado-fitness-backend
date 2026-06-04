# frozen_string_literal: true

require "net/http"
require "json"

class GeoIp
  ENDPOINT = "http://ip-api.com/json/%s?fields=countryCode"
  CACHE_TTL = 24.hours
  LOOPBACK_ADDRESSES = %w[127.0.0.1 ::1 localhost].freeze

  def self.argentina?(ip)
    country_code(ip) == "AR"
  end

  def self.country_code(ip)
    return nil if ip.blank? || LOOPBACK_ADDRESSES.include?(ip)

    Rails.cache.fetch("geo_ip:#{ip}", expires_in: CACHE_TTL) do
      fetch_country_code(ip)
    end
  end

  def self.fetch_country_code(ip)
    uri = URI(ENDPOINT % URI.encode_uri_component(ip))
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body)["countryCode"]
  rescue StandardError
    nil
  end
end
