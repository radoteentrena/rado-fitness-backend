module Admin
  module ConfirmDeleteHelper
    def confirm_delete_data(resource)
      { controller: "confirm-trigger" }.merge(confirm_attributes_for(resource))
    end

    private

    def confirm_attributes_for(resource)
      case resource
      when Program     then program_confirm_attributes(resource)
      when Routine     then routine_confirm_attributes(resource)
      when DietaryPlan then dietary_plan_confirm_attributes(resource)
      when Exercise    then exercise_confirm_attributes(resource)
      else { confirm_title: "Eliminar" }
      end
    end

    def program_confirm_attributes(program)
      return { confirm_title: "Eliminar Programa" } if program.user_id.blank?

      {
        confirm_mode: "block",
        confirm_title: "No se puede eliminar",
        confirm_message: "Este programa está asignado a un usuario y no puede eliminarse: desasígnalo primero."
      }
    end

    def routine_confirm_attributes(routine)
      return { confirm_title: "Eliminar Rutina" } if routine.user_id.blank?

      {
        confirm_mode: "block",
        confirm_title: "No se puede eliminar",
        confirm_message: "Esta rutina está asignada a un usuario y no puede eliminarse: desasígnala primero."
      }
    end

    def dietary_plan_confirm_attributes(plan)
      count = plan.user_dietary_plans.where(active: true).distinct.count(:user_id)
      attrs = { confirm_title: "Eliminar Plan Nutricional" }
      if count.positive?
        users = count == 1 ? "1 usuario activo" : "#{count} usuarios activos"
        attrs[:confirm_message] =
          "Este plan está asignado a #{users}. Sus objetivos actuales se mantienen, pero perderán el vínculo con esta plantilla."
      end
      attrs
    end

    def exercise_confirm_attributes(exercise)
      count = exercise.workouts.count
      attrs = { confirm_title: "Eliminar Ejercicio" }
      if count.positive?
        workouts = count == 1 ? "1 entrenamiento" : "#{count} entrenamientos"
        attrs[:confirm_message] = "Este ejercicio está en uso en #{workouts}. Se eliminará de todos ellos."
      end
      attrs
    end
  end
end
