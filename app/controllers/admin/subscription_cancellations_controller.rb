module Admin
  class SubscriptionCancellationsController < Admin::ApplicationController
    def create
      subscription = Subscription.find(params[:subscription_id])
      result = Subscriptions::Cancellation.new(subscription).call

      if result[:success]
        redirect_to admin_user_path(subscription.user),
                    notice: "Suscripción marcada para cancelar al vencimiento."
      else
        redirect_to admin_user_path(subscription.user),
                    alert: "Error al cancelar la suscripción."
      end
    end
  end
end
