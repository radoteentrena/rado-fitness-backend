class BookingsController < ApplicationController
  layout "homepage"
  before_action :authenticate_user!
  before_action :require_eligible_plan
  before_action :redirect_if_booked, only: [:new, :create]

  def new
    @available_dates = upcoming_working_dates
  end

  def create
    scheduled_at = parse_scheduled_at(params[:scheduled_at])

    unless slot_available?(scheduled_at)
      flash.now[:alert] = "El horario seleccionado ya no está disponible. Por favor elige otro."
      @available_dates = upcoming_working_dates
      return render :new, status: :unprocessable_entity
    end

    @booking = current_user.build_booking(scheduled_at: scheduled_at, status: :confirmed)
    unless @booking.valid?
      flash.now[:alert] = "No se pudo confirmar el agendamiento."
      @available_dates = upcoming_working_dates
      return render :new, status: :unprocessable_entity
    end

    access_token = GoogleCalendar::Auth.fresh_access_token
    result = GoogleCalendar::EventCreator.new(access_token).create(
      client_email: current_user.email,
      client_name: current_user.name,
      starts_at: scheduled_at
    )

    @booking.assign_attributes(
      google_event_id: result[:google_event_id],
      meet_link: result[:meet_link]
    )
    @booking.save!
    redirect_to booking_path
  rescue ArgumentError
    flash.now[:alert] = "Horario inválido."
    @available_dates = upcoming_working_dates
    render :new, status: :unprocessable_entity
  end

  def show
    @booking = current_user.booking
    redirect_to root_path unless @booking
  end

  private

  def require_eligible_plan
    unless current_user.medium_or_high_ticket?
      redirect_to root_path
    end
  end

  def redirect_if_booked
    redirect_to booking_path if current_user.booking.present?
  end

  def upcoming_working_dates
    active_days = CoachSchedule.where(active: true).pluck(:day_of_week)
    (1..7).filter_map do |offset|
      date = Date.today + offset
      date if active_days.include?(date.wday)
    end
  end

  def parse_scheduled_at(raw)
    Time.zone.parse(raw) or raise ArgumentError
  end

  def slot_available?(scheduled_at)
    date = scheduled_at.to_date
    schedule = CoachSchedule.find_by(day_of_week: date.wday, active: true)
    return false unless schedule

    access_token = GoogleCalendar::Auth.fresh_access_token
    busy = GoogleCalendar::FreeBusy.new(access_token).busy_intervals(
      date.beginning_of_day,
      date.end_of_day
    )

    available = GoogleCalendar::AvailabilityCalculator
                  .new(coach_schedule: schedule, busy_intervals: busy)
                  .available_slots(date)

    available.any? { |s| s == scheduled_at }
  end
end
