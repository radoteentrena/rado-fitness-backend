module Admin
  class ProgramChatController < Admin::ApplicationController
    before_action :set_program

    def show
      @conversation = find_or_create_conversation
      render layout: false
    end

    def message
      @conversation = find_or_create_conversation
      result = AiCoachService.new.refine(
        conversation:    @conversation,
        message:         params[:message],
        mode:            "program_chat",
        program_context: serialize_program(@program)
      )

      modifications = result[:structured_data]["modifications"] || []
      summary       = result[:structured_data]["summary"] || ""
      @conversation.update!(generated_data: { "pending_modifications" => modifications, "pending_summary" => summary })

      render turbo_stream: [
        turbo_stream.append("chat-messages",
          partial: "admin/program_chat/message_pair",
          locals:  { user_message: params[:message], modifications: modifications, summary: summary }),
        turbo_stream.replace("chat-apply-button",
          partial: "admin/program_chat/apply_button",
          locals:  { program: @program, conversation: @conversation,
                     routine_id: params[:routine_id], workout_id: params[:workout_id] }),
        turbo_stream.update("chat-error", "")
      ]
    rescue => e
      Rails.logger.error("ProgramChat message error: #{e.message}")
      render turbo_stream: turbo_stream.update("chat-error",
        partial: "admin/program_chat/error",
        locals:  { message: "Hubo un error con la IA. Por favor, intentá de nuevo." })
    end

    def apply
      @conversation = find_or_create_conversation
      modifications = @conversation.generated_data["pending_modifications"] || []
      patcher = ProgramPatchService.new(@program, modifications)
      patcher.call_modifications
      @conversation.update!(generated_data: { "pending_modifications" => [], "pending_summary" => "" })

      skipped = patcher.skipped_exercises.uniq
      streams = [
        turbo_stream.replace("chat-apply-button", ""),
        turbo_stream.update("chat-error",
          skipped.any? ? "Ejercicios omitidos (sin coincidencia en la biblioteca): #{skipped.join(', ')}" : "")
      ]

      if params[:routine_id].present?
        routine = Routine.find(params[:routine_id])
        reload_src = admin_routine_path(routine, workout_id: params[:workout_id].presence)
        streams << turbo_stream.replace("workout_content",
          html: view_context.turbo_frame_tag("workout_content", src: reload_src).to_s)
      end

      render turbo_stream: streams
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      Rails.logger.error("ProgramChat apply error: #{e.message}")
      render turbo_stream: turbo_stream.update("chat-error",
        partial: "admin/program_chat/error",
        locals:  { message: "Error al aplicar los cambios: #{e.message}" })
    end

    private

    def set_program
      @program = Program.find(params[:program_id])
    end

    def find_or_create_conversation
      AiConversation.find_or_create_by!(program: @program, objectives: "Chat de programa: #{@program.name}") do |c|
        c.user           = @program.user
        c.generated_data = { "pending_modifications" => [], "pending_summary" => "" }
        c.status         = "active"
      end
    end

    def serialize_program(program)
      phases = program.phases
                      .includes(phase_routines: { routine: { workouts: { workout_exercises: :exercise } } })
                      .order(:order_index)

      routines_data = phases.flat_map do |phase|
        phase.phase_routines.order(:order_index).map do |pr|
          routine = pr.routine
          {
            "id"          => routine.id,
            "name"        => routine.name,
            "description" => routine.description,
            "workouts"    => routine.workouts.order(:order_index).map do |workout|
              {
                "id"          => workout.id,
                "name"        => workout.name,
                "description" => workout.description,
                "day_number"  => workout.day_number,
                "exercises"   => workout.workout_exercises.order(:order_index).map do |we|
                  {
                    "workout_exercise_id" => we.id,
                    "workout_id"          => workout.id,
                    "exercise_id"         => we.exercise_id,
                    "name"                => we.exercise.name,
                    "sets"                => we.sets,
                    "reps"                => we.reps,
                    "rest_seconds"        => we.rest_seconds,
                    "intensity_technique" => we.intensity_technique,
                    "load"                => we.load
                  }
                end
              }
            end
          }
        end
      end

      {
        "program"  => { "id" => program.id, "name" => program.name, "duration_weeks" => program.duration_weeks },
        "routines" => routines_data
      }
    end
  end
end
