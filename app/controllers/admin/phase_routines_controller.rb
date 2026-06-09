module Admin
  class PhaseRoutinesController < Admin::ApplicationController
    def destroy
      resource = requested_resource
      phase = resource.phase
      resource.destroy!

      respond_to do |format|
        format.turbo_stream { render locals: { resource: resource, phase: phase } }
        format.html { redirect_to admin_program_builder_path(program_id: phase.program_id), notice: "Routine removed from phase." }
      end
    end

    def create
      if params[:new_routine_name_mode].present?
        create_new_routine_and_assign
      else
        create_existing_routine_assignment
      end
    end

    private

    def create_new_routine_and_assign
      phase = Phase.find(params[:phase_routine][:phase_id])
      program = phase.program

      if params[:new_routine_name].blank?
        raise ActiveRecord::RecordInvalid.new(Routine.new.tap { |r| r.errors.add(:name, "can't be blank") })
      end

      ActiveRecord::Base.transaction do
        routine = Routine.create!(
          name: params[:new_routine_name],
          is_template: false,
          user: program.user
        )
        @resource = PhaseRoutine.create!(phase: phase, routine: routine)
      end

      respond_to do |format|
        format.turbo_stream { render :create, locals: { resource: @resource } }
        format.html { redirect_to admin_program_builder_path(program_id: phase.program_id), notice: "Routine created and added." }
      end
    rescue ActiveRecord::RecordInvalid => e
      new_resource = resource_class.new
      error_locals = {
        page: Administrate::Page::Form.new(dashboard, new_resource),
        modal_screen: "new",
        new_routine_error: e.message
      }

      respond_to do |format|
        format.turbo_stream { render :new, locals: error_locals, status: :unprocessable_entity }
        format.html { render :new, locals: error_locals, status: :unprocessable_entity }
      end
    end

    def create_existing_routine_assignment
      resource = resource_class.new(resource_params)
      authorize_resource(resource)

      if resource.save
        respond_to do |format|
          format.html { redirect_to [namespace, resource], notice: translate_with_resource("create.success") }
          format.turbo_stream { render locals: { resource: resource } }
        end
      else
        respond_to do |format|
          format.html { render :new, locals: { page: Administrate::Page::Form.new(dashboard, resource) }, status: :unprocessable_entity }
        end
      end
    end
  end
end
