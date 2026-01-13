class Avo::Resources::Routine < Avo::BaseResource
  self.title = :name
  # self.includes = []
  # self.attachments = []
  self.search = {
    query: -> { query.ransack(name_cont: q).result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :description, as: :textarea
    field :user, as: :belongs_to
    field :is_template, as: :boolean
    field :routine_items, as: :has_many
  end
end
