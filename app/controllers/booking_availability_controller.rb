class BookingAvailabilityController < ApplicationController
  before_action :authenticate_user!

  def show
    date = Date.parse(params[:date])
    schedule = CoachSchedule.find_by(day_of_week: date.wday, active: true)

    if schedule.nil?
      render json: { slots: [] } and return
    end

    access_token = GoogleCalendar::Auth.fresh_access_token
    busy = GoogleCalendar::FreeBusy.new(access_token).busy_intervals(
      date.beginning_of_day,
      date.end_of_day
    )

    slots = GoogleCalendar::AvailabilityCalculator
              .new(coach_schedule: schedule, busy_intervals: busy)
              .available_slots(date)

    render json: { slots: slots.map { |s| s.strftime("%H:%M") } }
  rescue ArgumentError
    render json: { error: "Fecha inválida" }, status: :bad_request
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Google Calendar no conectado" }, status: :service_unavailable
  end
end
