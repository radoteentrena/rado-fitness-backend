class Avo::Resources::RoutineItem < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :routine, as: :belongs_to
    field :exercise, as: :belongs_to
    field :sets, as: :number
    field :reps, as: :text
    field :rir, as: :text
    field :rest_seconds, as: :number
    field :order_index, as: :number
  end
end
