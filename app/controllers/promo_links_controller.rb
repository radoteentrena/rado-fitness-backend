class PromoLinksController < ApplicationController
  before_action :authenticate_user!
  before_action :require_promoter

  def create
    label = params.require(:promo_link).permit(:label)[:label].to_s.strip
    if label.blank?
      redirect_to account_path(tab: "campaign"), alert: "El nombre del enlace no puede estar vacío."
      return
    end

    @promo_link = current_user.promo_links.build(label: label)

    if @promo_link.save
      redirect_to account_path(tab: "campaign"), notice: "Enlace creado correctamente."
    else
      redirect_to account_path(tab: "campaign"), alert: @promo_link.errors.full_messages.join(", ")
    end
  end

  def update
    @promo_link = current_user.promo_links.find(params[:id])
    @promo_link.update!(active: false)
    redirect_to account_path(tab: "campaign"), notice: "Enlace desactivado."
  end

  private

  def require_promoter
    redirect_to account_path unless current_user.promoter?
  end
end
