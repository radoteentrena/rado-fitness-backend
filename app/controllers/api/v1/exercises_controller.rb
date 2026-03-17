class Api::V1::ExercisesController < Api::V1::BaseController
  def index
    @exercises = Exercise.all.order(:name)
  end
end
