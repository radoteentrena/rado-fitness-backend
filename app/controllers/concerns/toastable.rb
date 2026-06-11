module Toastable
  extend ActiveSupport::Concern

  included do
    after_action :flash_to_toast, only: %i[create update destroy]
  end

  private

  def flash_to_toast
    if flash[:notice].present?
      flash[:toast] = { "message" => flash[:notice], "type" => "success" }
      flash.delete(:notice)
    elsif flash[:alert].present?
      flash[:toast] = { "message" => flash[:alert], "type" => "error" }
      flash.delete(:alert)
    end
  end
end
