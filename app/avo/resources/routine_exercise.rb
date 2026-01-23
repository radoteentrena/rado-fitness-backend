class Avo::Resources::RoutineExercise < Avo::BaseResource
  def fields
    field :id, as: :id
    field :routine, as: :belongs_to
    field :exercise, as: :belongs_to
    field :day_number, as: :number
    field :day_name, as: :text
    field :sets, as: :number
    field :reps, as: :text
    field :load, as: :text
    field :rir, as: :text
    field :rest_seconds, as: :number, name: "Rest (sec)"
    field :warmup, as: :boolean
    field :sub_option, as: :number
    field :instructions, as: :textarea
    field :order_index, as: :number
  end
end
