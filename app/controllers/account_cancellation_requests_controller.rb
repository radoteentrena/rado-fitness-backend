# frozen_string_literal: true

class AccountCancellationRequestsController < ApplicationController
  before_action :authenticate_user!

  def create
    CoachAlert.create!(
      user: current_user,
      category: :cancellation_request,
      message: "El cliente solicitó la cancelación de su suscripción (#{current_user.plan_tier&.humanize}).",
      status: :pending
    )
    redirect_to account_path, notice: "Solicitud enviada. Rado se pondrá en contacto a la brevedad."
  end
end
