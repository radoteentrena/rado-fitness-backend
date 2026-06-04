class PagesController < ApplicationController
  layout "homepage"

  def home
    @argentina = GeoIp.argentina?(request.remote_ip)
  end

  def terms
  end

  def privacy
  end
end
