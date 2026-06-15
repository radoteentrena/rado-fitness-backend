namespace :exercises do
  desc "Consolidate videoless exercises into their video-bearing name twin. Dry-run unless APPLY=1."
  task heal_missing_videos: :environment do
    apply  = ENV["APPLY"] == "1"
    puts apply ? "⚙️  APPLYING consolidations…" : "🔎 DRY RUN — set APPLY=1 to execute."

    merges = ExerciseVideoHealer.new(apply: apply).call

    if merges.empty?
      puts "✅ No videoless exercises with a matching video-bearing twin found."
      next
    end

    merges.each do |m|
      puts "• '#{m.duplicate.name}' (##{m.duplicate.id}, no video) → " \
           "'#{m.canonical.name}' (##{m.canonical.id}, has video)"
      puts "    #{m.workout_exercise_count} workout exercise(s) across #{m.routine_count} routine(s) repointed"
    end

    verb = apply ? "consolidated and deleted" : "would be consolidated"
    puts "\n#{merges.size} duplicate exercise(s) #{verb}."
    puts "Re-run with APPLY=1 to apply." unless apply
  end
end
