require "google/apis/sheets_v4"
require "googleauth"

module Google
  class SheetsService
    APPLICATION_NAME = "Rado Fitness".freeze
    SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

    def initialize(program)
      @program = program
      @service = Google::Apis::SheetsV4::SheetsService.new
      @service.client_options.application_name = APPLICATION_NAME
      @service.authorization = authorize
    end

    def create_program_sheet
      return unless @service.authorization

      spreadsheet = Google::Apis::SheetsV4::Spreadsheet.new(
        properties: {
          title: "Rado Fitness - #{@program.name} - #{@program.user&.name}",
          locale: "es_ES"
        }
      )

      file = @service.create_spreadsheet(spreadsheet)

      @program.update!(google_sheet_link: file.spreadsheet_url)

      # Prepare headers
      setup_headers(file.spreadsheet_id)

      file.spreadsheet_url
    rescue => e
      Rails.logger.error "Google::SheetsService Error: #{e.message}"
      nil
    end

    private

    def authorize
      # Check for credentials in ENV or file
      if ENV["GOOGLE_APPLICATION_CREDENTIALS"].present? || File.exist?("config/google_credentials.json")
        Google::Auth.get_application_default(SCOPE)
      else
        Rails.logger.warn "Google Credentials not found. Sheets integration skipped."
        nil
      end
    end

    def setup_headers(spreadsheet_id)
      # Setup basic structure
      range = "Sheet1!A1:E1"
      values = [ [ "Week", "Day", "Exercise", "Sets x Reps", "Log (Weight)" ] ]

      value_range = Google::Apis::SheetsV4::ValueRange.new(values: values)
      @service.update_spreadsheet_value(spreadsheet_id, range, value_range, value_input_option: "RAW")
    end
  end
end
