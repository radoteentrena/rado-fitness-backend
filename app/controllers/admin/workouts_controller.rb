class Admin::WorkoutsController < Admin::ApplicationController
  before_action :set_routine, only: [ :new, :create ]
  before_action :set_workout, only: [ :edit, :update, :destroy ]

  def new
    @workout = @routine.workouts.build
  end

  def create
    @workout = @routine.workouts.build(workout_params)

    # Auto-assign day number/order index logic
    if @workout.day_number.blank?
      @workout.day_number = (@routine.workouts.maximum(:day_number) || 0) + 1
    end
    if @workout.order_index.blank?
      @workout.order_index = (@routine.workouts.maximum(:order_index) || 0) + 1
    end

    if @workout.save
      redirect_to admin_routine_path(@routine), notice: "Workout was successfully created.", status: :see_other
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @workout.update(workout_params)
      redirect_to admin_routine_path(@workout.routine), notice: "Workout was successfully updated.", status: :see_other
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    routine = @workout.routine
    @workout.destroy
    redirect_to admin_routine_path(routine), notice: "Workout was successfully destroyed.", status: :see_other
  end

  private

  def set_routine
    @routine = Routine.find(params[:routine_id] || params.dig(:workout, :routine_id))
  end

  def set_workout
    @workout = Workout.find(params[:id])
  end

  def workout_params
    params.require(:workout).permit(:name, :description, :day_number, :order_index)
  end
end
