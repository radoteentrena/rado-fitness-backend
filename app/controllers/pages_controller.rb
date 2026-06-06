class PagesController < ApplicationController
  layout "homepage"

  def home
    @argentina = GeoIp.argentina?(request.remote_ip)
    @prices = {
      basic:       Subscriptions::Pricing.base_price(:basic,       argentina: @argentina),
      medium:      Subscriptions::Pricing.base_price(:medium,      argentina: @argentina),
      high_ticket: Subscriptions::Pricing.base_price(:high_ticket, argentina: @argentina)
    }
  end

  def terms
  end

  def privacy
  end
end
