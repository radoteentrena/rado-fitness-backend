# Matches AI-generated exercise data to existing Exercise records.
#
# The AI coach must reuse exercises from the coach's library and never invent
# new ones, so that every workout exercise keeps the coach-entered video_link.
# Anything that can't be matched is skipped and recorded in #skipped so the
# caller can report it.
class ExerciseResolver
  def initialize
    @by_id   = {}
    @by_name = {}
    Exercise.find_each do |ex|
      @by_id[ex.id]                = ex
      @by_name[normalize(ex.name)] = ex
    end
    @skipped = []
  end

  attr_reader :skipped

  # Returns the matching Exercise, or nil if none exists (recording the miss).
  # Matches by name first (accent/case-insensitive) — the AI sees names, and
  # names carry a unique index — then falls back to the id it was given.
  def resolve(ex_data)
    name = ex_data["name"].to_s
    id   = ex_data["existing_exercise_id"]

    match = @by_name[normalize(name)] || (@by_id[id.to_i] if id.present?)
    @skipped << name.presence || "(sin nombre)" unless match
    match
  end

  private

  def normalize(str)
    I18n.transliterate(str.to_s).downcase.strip.gsub(/\s+/, " ")
  end
end
