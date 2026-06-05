class PromoLinksController < ApplicationController
  before_action :authenticate_user!
  before_action :require_promoter

  def create
    @promo_link = current_user.promo_links.build(
      label: params.require(:promo_link).permit(:label)[:label]
    )

    if @promo_link.save
      redirect_to account_path(tab: "campaign"), notice: "Enlace creado correctamente."
    else
      redirect_to account_path(tab: "campaign"), alert: "Error al crear el enlace."
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
