class Avo::Resources::Program < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :duration_weeks, as: :number
    field :description, as: :textarea
    field :user, as: :belongs_to
    field :routines, as: :has_many
  end
end
