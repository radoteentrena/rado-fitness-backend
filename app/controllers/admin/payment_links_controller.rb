module Admin
  class PaymentLinksController < Admin::ApplicationController
    def create
      user = User.find(params[:user_id])
      token = user.generate_payment_token!
      url = pay_url(token)

      render turbo_stream: turbo_stream.update(
        "payment_link_result",
        partial: "admin/users/payment_link",
        locals: { url: url, expires_at: user.payment_link_expires_at }
      )
    end
  end
end
