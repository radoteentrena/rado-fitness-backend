module Google
  class CalendarService
    def initialize(user)
      @user = user
    end

    def list_availability(start_date, end_date)
      # Mock implementation for MVP
      # Returns sample available slots for the next 7 days
      start_date = Date.parse(start_date) if start_date.is_a?(String)

      (0..4).map do |day_offset|
        date = start_date + day_offset.days
        next if date.saturday? || date.sunday? # Mock: Rado works Mon-Fri

        {
          date: date.to_s,
          slots: [ "10:00", "14:00", "16:00" ]
        }
      end.compact
    end

    def create_event(start_time, end_time, summary)
      # TODO: Implement Google Calendar Event creation
      # Returns event object or ID
    end
  end
end
