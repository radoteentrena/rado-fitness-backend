module GoogleCalendar
  class EventCreator
    DURATION_MINUTES = 60

    def initialize(access_token)
      @service = build_service(access_token)
    end

    # Returns { google_event_id:, meet_link: }
    def create(client_email:, client_name:, starts_at:)
      ends_at = starts_at + DURATION_MINUTES.minutes
      event = Google::Apis::CalendarV3::Event.new(
        summary: "Llamada de inicio — #{client_name}",
        start: time_object(starts_at),
        end: time_object(ends_at),
        attendees: [
          Google::Apis::CalendarV3::EventAttendee.new(email: ENV.fetch("RADO_EMAIL")),
          Google::Apis::CalendarV3::EventAttendee.new(email: client_email)
        ],
        conference_data: Google::Apis::CalendarV3::ConferenceData.new(
          create_request: Google::Apis::CalendarV3::CreateConferenceRequest.new(
            request_id: SecureRandom.hex(8),
            conference_solution_key: Google::Apis::CalendarV3::ConferenceSolutionKey.new(type: "hangoutsMeet")
          )
        )
      )
      result = @service.insert_event("primary", event, conference_data_version: 1, send_updates: "all")
      meet_link = result.conference_data&.entry_points&.find { |ep| ep.entry_point_type == "video" }&.uri
      { google_event_id: result.id, meet_link: meet_link }
    end

    private

    def build_service(access_token)
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = Google::Auth::UserRefreshCredentials.new(
        access_token: access_token
      )
      service
    end

    def time_object(time)
      Google::Apis::CalendarV3::EventDateTime.new(
        date_time: time.iso8601,
        time_zone: "America/Argentina/Buenos_Aires"
      )
    end
  end
end
