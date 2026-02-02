class Avo::Resources::DailyMetric < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :user, as: :belongs_to
    field :date_logged, as: :date
    field :calories_consumed, as: :number
    field :protein_consumed, as: :number
    field :steps, as: :number
    field :weight, as: :number
    field :raw_message_content, as: :textarea, rows: 5
    field :compliant, as: :boolean
    field :on_target, as: :boolean
    field :ai_parsed_json, as: :code, language: "json"
  end
end
