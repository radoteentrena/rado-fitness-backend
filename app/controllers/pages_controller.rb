class PagesController < ApplicationController
  layout "homepage", only: [:home]

  def home
  end
end
