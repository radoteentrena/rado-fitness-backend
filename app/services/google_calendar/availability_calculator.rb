module GoogleCalendar
  class AvailabilityCalculator
    SLOT_DURATION = 60 # minutes

    def initialize(coach_schedule:, busy_intervals:)
      @schedule = coach_schedule
      @busy = busy_intervals
    end

    # Returns array of Time objects representing available slot start times for a given date
    def available_slots(date)
      return [] unless @schedule&.active

      slots = generate_slots(date)
      slots.reject { |slot| conflicts?(slot) }
    end

    private

    def generate_slots(date)
      start_time = Time.zone.parse("#{date} #{@schedule.start_hour}:00:00")
      end_time   = Time.zone.parse("#{date} #{@schedule.end_hour}:00:00")
      slots = []
      current = start_time
      while current + SLOT_DURATION.minutes <= end_time
        slots << current
        current += SLOT_DURATION.minutes
      end
      slots
    end

    def conflicts?(slot)
      slot_end = slot + SLOT_DURATION.minutes
      @busy.any? do |busy|
        busy_start = busy[:start].is_a?(String) ? Time.parse(busy[:start]) : busy[:start]
        busy_end   = busy[:end].is_a?(String)   ? Time.parse(busy[:end])   : busy[:end]
        slot < busy_end && slot_end > busy_start
      end
    end
  end
end
