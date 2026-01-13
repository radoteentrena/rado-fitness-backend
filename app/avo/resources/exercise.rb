class Avo::Resources::Exercise < Avo::BaseResource
  self.title = :name
  # self.includes = []
  # self.attachments = []
  self.search = {
    query: -> { query.ransack(name_cont: q).result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :video_link, as: :text
    field :muscle_group, as: :text
    field :description, as: :textarea
  end
end
