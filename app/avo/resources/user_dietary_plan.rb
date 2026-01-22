class Avo::Resources::UserDietaryPlan < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :user, as: :belongs_to
    field :calories_target, as: :number
    field :protein_target, as: :number
    field :notes, as: :textarea
  end
end
