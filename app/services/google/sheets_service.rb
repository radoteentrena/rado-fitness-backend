require "google/apis/sheets_v4"
require "google/apis/drive_v3"
require "googleauth"

module Google
  class SheetsService
    APPLICATION_NAME = "Rado Fitness".freeze
    SCOPE = [
      Google::Apis::SheetsV4::AUTH_SPREADSHEETS,
      Google::Apis::DriveV3::AUTH_DRIVE
    ].freeze

    def initialize(program)
      @program = program
      @service = Google::Apis::SheetsV4::SheetsService.new
      @service.client_options.application_name = APPLICATION_NAME
      @service.authorization = authorize
    end

    def sync_to_db
      return unless @service.authorization && spreadsheet_id

      spreadsheet = @service.get_spreadsheet(spreadsheet_id)

      spreadsheet.sheets.each do |sheet|
        sheet_title = sheet.properties.title
        next if sheet_title == "Sheet1" && @program.routines.none? { |r| sanitize_sheet_title(r.name) == "Sheet1" }

        # Read all values
        range = "#{sheet_title}!A:N"
        response = @service.get_spreadsheet_values(spreadsheet_id, range)
        values = response.values

        next unless values && values.length > 1 # Skip if explicitly empty or just header

        # Map Headers to Index
        headers = values[0]
        # We assume strict column order for now as per HEADER_ROW, but could be dynamic.

        # Iterate Data Rows
        values[1..-1].each do |row|
          # Parse columns based on index
          # 0: Week, 1: Routine, 2: Exercise, 3: Intensity, 4: Warmup, 5: Sets, 6: Reps
          # 7: Early RPE, 8: Last RPE, 9: Rest, 10: Sub 1, 11: Sub 2, 12: Time, 13: ID

          routine_exercise_id = row[13]
          next unless routine_exercise_id.present?

          re = RoutineExercise.find_by(id: routine_exercise_id)
          next unless re

          # Updates
          updates = {
            intensity_technique: row[3],
            warmup_sets: row[4],
            sets: row[5].to_i, # Cast to int
            reps: row[6],
            early_rpe: row[7],
            last_rpe: row[8],
            rest_seconds: row[9],
            sub_option_one: row[10],
            sub_option_two: row[11],
            time_estimate: row[12]
          }

          # Only update if changed prevents useless queries, but Rails handles dirty checking.
          re.update(updates)
        end
      end

      @program.touch(:last_synced_at)
    end

    private

    def authorize
      if ENV["GOOGLE_REFRESH_TOKEN"].present? && ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
        Google::Auth::UserRefreshCredentials.new(
          client_id: ENV["GOOGLE_CLIENT_ID"],
          client_secret: ENV["GOOGLE_CLIENT_SECRET"],
          scope: SCOPE,
          refresh_token: ENV["GOOGLE_REFRESH_TOKEN"]
        )
      elsif ENV["GOOGLE_APPLICATION_CREDENTIALS"].present?
        Google::Auth.get_application_default(SCOPE)
      elsif File.exist?("config/google_credentials.json")
        Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: File.open("config/google_credentials.json"),
          scope: SCOPE
        )
      else
        Rails.logger.warn "Google Credentials not found. Sheets integration skipped."
        nil
      end
    end

    def spreadsheet_id
      return nil unless @program.google_sheet_link
      @program.google_sheet_link.scan(/\/d\/(.*?)(\/|$)/).flatten.first
    end

    def sanitize_sheet_title(name)
      name.to_s.gsub(/[\/\\\?\*\[\]\:]/, "_").truncate(99)
    end
  end
end
