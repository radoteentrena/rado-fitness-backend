class Avo::Resources::UserDietaryPlan < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :user, as: :belongs_to
    field :dietary_plan, as: :belongs_to, name: "Template"

    field "Status", as: :heading
    field :active, as: :boolean
    field :start_date, as: :date
    field :end_date, as: :date

    field "Targets", as: :heading
    field :calories_target, as: :number
    field :protein_target, as: :number
    field :notes, as: :textarea

    field "Progress (Computed)", as: :heading
    field :average_calories, as: :number, readonly: true
    field :average_weight, as: :number, readonly: true
    field :weight_progress, as: :number, readonly: true

    field :daily_metrics, as: :has_many
  end
end
