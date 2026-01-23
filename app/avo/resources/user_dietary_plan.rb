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

    heading "Status"
    field :active, as: :boolean
    field :start_date, as: :date
    field :end_date, as: :date

    heading "Targets"
    field :calories_target, as: :number
    field :protein_target, as: :number
    field :notes, as: :textarea

    heading "Progress (Computed)"
    field :average_calories, as: :number, readonly: true
    field :average_weight, as: :number, readonly: true
    field :weight_progress, as: :number, readonly: true

    field :daily_metrics, as: :has_many
  end
end
