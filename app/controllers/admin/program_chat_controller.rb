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
        conversation: @conversation,
        message:      params[:message],
        mode:         "program_chat"
      )

      render turbo_stream: [
        turbo_stream.append("chat-messages",
          partial: "admin/program_chat/message_pair",
          locals:  { user_message: params[:message], ai_json: result[:structured_data] }),
        turbo_stream.replace("chat-apply-button",
          partial: "admin/program_chat/apply_button",
          locals:  { program: @program, conversation: @conversation })
      ]
    rescue => e
      Rails.logger.error("ProgramChat message error: #{e.message}")
      render turbo_stream: turbo_stream.replace("chat-error",
        partial: "admin/program_chat/error",
        locals:  { message: e.message })
    end

    def apply
      @conversation = find_or_create_conversation
      ProgramPatchService.new(@program, @conversation.generated_data).call
      @conversation.update!(generated_data: serialize_program(@program.reload))

      phases = @program.phases
                       .includes(routines: :user)
                       .order(:order_index)

      render turbo_stream: [
        turbo_stream.replace("program-builder-content",
          partial: "admin/program_builders/content",
          locals:  { program: @program, phases: phases }),
        turbo_stream.replace("chat-apply-button", "")
      ]
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      Rails.logger.error("ProgramChat apply error: #{e.message}")
      render turbo_stream: turbo_stream.replace("chat-error",
        partial: "admin/program_chat/error",
        locals:  { message: e.message })
    end

    private

    def set_program
      @program = Program.find(params[:program_id])
    end

    def find_or_create_conversation
      AiConversation.find_or_create_by!(program: @program, status: "active") do |c|
        c.user           = @program.user
        c.objectives     = "Chat de programa: #{@program.name}"
        c.generated_data = serialize_program(@program)
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
