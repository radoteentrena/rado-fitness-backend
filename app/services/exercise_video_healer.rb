# Heals exercises that have no video_link by consolidating them into a
# normalized-name twin that already has one — the residue of the old AI coach
# behaviour that created duplicate exercises instead of reusing the library.
#
# Safe by construction: workout_exercises are repointed to the canonical
# (video-bearing) exercise FIRST, and the duplicate is only deleted once it has
# zero remaining references (all inside a transaction). Client training history
# (exercise_logs) keys on workout_exercise_id, so it is never affected.
class ExerciseVideoHealer
  Merge = Struct.new(:canonical, :duplicate, :workout_exercise_count, :routine_count, keyword_init: true)

  def initialize(apply: false)
    @apply = apply
  end

  # Returns an array of Merge describing the consolidations (planned in dry-run,
  # executed when apply: true).
  def call
    merges = []

    Exercise.includes(:workout_exercises).group_by { |e| normalize(e.name) }.each_value do |group|
      next if group.size < 2

      with_video    = group.select { |e| e.video_link.present? }
      without_video = group.select { |e| e.video_link.blank? }
      next if with_video.empty? || without_video.empty?

      canonical = with_video.min_by(&:id)

      without_video.each do |duplicate|
        scope = WorkoutExercise.where(exercise_id: duplicate.id)
        merges << Merge.new(
          canonical:              canonical,
          duplicate:              duplicate,
          workout_exercise_count: scope.count,
          routine_count:          scope.joins(:workout).distinct.count("workouts.routine_id")
        )

        consolidate!(duplicate, canonical) if @apply
      end
    end

    merges
  end

  private

  def consolidate!(duplicate, canonical)
    ActiveRecord::Base.transaction do
      WorkoutExercise.where(exercise_id: duplicate.id)
                     .update_all(exercise_id: canonical.id, updated_at: Time.current)

      duplicate.reload
      raise "Exercise ##{duplicate.id} still referenced — aborting delete" if duplicate.workout_exercises.exists?

      duplicate.destroy!
    end
  end

  # Same rule as ExerciseResolver: accent/case-insensitive, whitespace-collapsed.
  def normalize(str)
    I18n.transliterate(str.to_s).downcase.strip.gsub(/\s+/, " ")
  end
end
