class MigrateRoutinesToPhaseRoutines < ActiveRecord::Migration[8.0]
  class Routine < ActiveRecord::Base; end
  class PhaseRoutine < ActiveRecord::Base; end

  def up
    Routine.where.not(phase_id: nil).find_each do |routine|
      PhaseRoutine.create!(
        phase_id: routine.phase_id,
        routine_id: routine.id,
        order_index: 0
      )
    end
    remove_reference :routines, :phase, foreign_key: true
  end

  def down
    add_reference :routines, :phase, foreign_key: true
    PhaseRoutine.find_each do |pr|
      routine = Routine.find_by(id: pr.routine_id)
      routine.update_column(:phase_id, pr.phase_id) if routine
    end
  end
end
