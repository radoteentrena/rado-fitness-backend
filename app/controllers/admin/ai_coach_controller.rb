module Admin
  class AiCoachController < Admin::ApplicationController
    before_action :set_conversation, only: [ :refine, :approve ]

    # Step 1: Show the wizard form (client selection + objectives)
    def new
      @users = User.order(:first_name)
    end

    # Step 2: Generate a program from objectives
    def generate
      service = AiCoachService.new
      user = params[:user_id].present? ? User.find(params[:user_id]) : nil

      result = service.generate_program(
        objectives: params[:objectives],
        user: user,
        mode: params[:mode] || "program"
      )

      @conversation = result[:conversation]
      @structured_data = result[:structured_data]

      if @structured_data.empty?
        flash.now[:alert] = "The AI failed to generate a valid program format. Please adjust your prompt and try again."
      end

      respond_to do |format|
        format.turbo_stream
        format.html { render :preview }
      end
    rescue => e
      Rails.logger.error("AI Coach Error: #{e.message}")
      redirect_to admin_new_ai_coach_path, alert: "Error generating program: #{e.message}"
    end

    # Chat refinement: modify the generated program
    def refine
      service = AiCoachService.new
      result = service.refine(
        conversation: @conversation,
        message: params[:message]
      )

      @structured_data = result[:structured_data]

      respond_to do |format|
        format.turbo_stream
        format.html { render :preview }
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
