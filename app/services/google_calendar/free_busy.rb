module GoogleCalendar
  class FreeBusy
    def initialize(access_token)
      @service = build_service(access_token)
    end

    # Returns array of {start: Time, end: Time} busy intervals for a given date range
    def busy_intervals(date_from, date_to)
      request = Google::Apis::CalendarV3::FreeBusyRequest.new(
        time_min: date_from.iso8601,
        time_max: date_to.iso8601,
        items: [ Google::Apis::CalendarV3::FreeBusyRequestItem.new(id: "primary") ]
      )
      response = @service.query_freebusy(request)
      raw_busy = response.calendars["primary"]&.busy || []
      raw_busy.map { |b| { start: b.start, end: b.end } }
    end

    private

    def build_service(access_token)
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = Google::Auth::UserRefreshCredentials.new(
        access_token: access_token
      )
      service
    end
  end
end
