class ProgramMatcherService
  FREQUENCY_WORKOUT_MAP = {
    "2"        => 2,
    "3"        => 3,
    "4"        => 4,
    "+4 veces" => 5
  }.freeze

  def initialize(user, force: false)
    @user  = user
    @force = force
  end

  def call
    return nil if !@force && @user.programs.exists?

    templates = Program.where(user_id: nil)
                       .includes(phases: { phase_routines: { routine: :workouts } })

    if templates.empty?
      Rails.logger.warn("ProgramMatcher: no templates exist for user #{@user.id}")
      return nil
    end

    best = select_best(templates)
    best.assign_to_user(@user)
  end

  private

  def select_best(templates)
    shortlist = pre_filter(templates)
    shortlist = templates.order(:id).to_a if shortlist.empty?

    return shortlist.min_by(&:id) unless @user.onboarding_profile

    ai_rank(shortlist) || shortlist.min_by(&:id)
  rescue => e
    Rails.logger.error("ProgramMatcher ranking failed: #{e.message}")
    templates.order(:id).first
  end

  def pre_filter(templates)
    profile = @user.onboarding_profile
    return templates.to_a if profile.nil?

    target = FREQUENCY_WORKOUT_MAP[profile.training_frequency]
    return templates.to_a if target.nil?

    templates.select do |t|
      phase = t.phases.sort_by(&:order_index).first
      routine = phase&.phase_routines&.sort_by(&:order_index)&.first&.routine
      next false unless routine

      count = routine.workouts.size
      target >= 5 ? count >= 5 : count == target
    end
  end

  def ai_rank(shortlist)
    AiCoachService.new.rank_programs(shortlist, @user)
  rescue => e
    Rails.logger.error("ProgramMatcher Gemini call failed: #{e.message}")
    nil
  end
end
