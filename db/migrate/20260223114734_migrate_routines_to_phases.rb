class MigrateRoutinesToPhases < ActiveRecord::Migration[8.0]
  class Program < ActiveRecord::Base; end
  class Phase < ActiveRecord::Base; end
  class Routine < ActiveRecord::Base; end
  class UserDietaryPlan < ActiveRecord::Base; end

  def up
    Program.find_each do |program|
      phase = Phase.create!(
        program_id: program.id,
        name: "Phase 1",
        description: "Initial phase",
        order_index: 1,
        duration_weeks: program.duration_weeks || 4
      )

      Routine.where(program_id: program.id).update_all(phase_id: phase.id)
    end

    UserDietaryPlan.where(active: true).find_each do |udp|
      latest_program = Program.where(user_id: udp.user_id).order(created_at: :desc).first
      if latest_program
        first_phase = Phase.where(program_id: latest_program.id).order(:order_index).first
        udp.update_column(:phase_id, first_phase.id) if first_phase
      end
    end
  end

  def down
    Routine.update_all(phase_id: nil)
    UserDietaryPlan.update_all(phase_id: nil)
    Phase.delete_all
  end
end
