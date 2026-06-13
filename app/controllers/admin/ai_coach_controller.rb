module Admin
  class AiCoachController < Admin::ApplicationController
    before_action :set_conversation, only: [ :refine, :approve ]

    # Step 1: Show the wizard form (client selection + objectives)
    def new
      @users = User.order(:first_name)
    end

    # Step 2: Generate a program from objectives.
    # The AI call is offloaded to a background job so the request returns
    # immediately; the result is streamed in via Turbo when the job finishes.
    def generate
      user = params[:user_id].present? ? User.find(params[:user_id]) : nil

      @conversation = AiConversation.create!(
        user:       user,
        objectives: params[:objectives],
        title:      "Generando…",
        status:     "generating"
      )

      AiCoachGenerationJob.perform_later(
        @conversation.id,
        mode:   params[:mode].presence || "program",
        gender: params[:gender].presence,
        focus:  params[:focus].presence,
        level:  params[:level].presence
      )

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_new_ai_coach_path }
      end
    rescue => e
      Rails.logger.error("AI Coach Error: #{e.message}")
      redirect_to admin_new_ai_coach_path, alert: "Error generating program: #{e.message}"
    end

    # Chat refinement: modify the generated program (also offloaded to a job).
    def refine
      AiCoachRefinementJob.perform_later(@conversation.id, params[:message])

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_new_ai_coach_path }
      end
    rescue => e
      Rails.logger.error("AI Coach Refine Error: #{e.message}")
      redirect_to admin_new_ai_coach_path, alert: "Error refining program: #{e.message}"
    end

    # Step 3: Approve and create actual records
    def approve
      # Allow inline edits to override the generated data
      if params[:structured_data].present?
        @conversation.update!(generated_data: JSON.parse(params[:structured_data]))
      end

      service = AiCoachService.new
      record = service.create_records!(@conversation)

      if record.is_a?(Program)
        redirect_to admin_program_path(record), notice: "Program created successfully!"
      else
        redirect_to admin_routine_path(record), notice: "Routine created successfully!"
      end
    rescue => e
      Rails.logger.error("AI Coach Approve Error: #{e.message}")
      redirect_to admin_new_ai_coach_path, alert: "Error creating records: #{e.message}"
    end

    private

    def set_conversation
      @conversation = AiConversation.find(params[:conversation_id])
    end
  end
end
