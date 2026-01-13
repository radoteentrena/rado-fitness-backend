class Avo::Resources::User < Avo::BaseResource
  self.title = :name
  # self.includes = []
  # self.attachments = []
  self.search = {
    query: -> { query.ransack(first_name_cont: q, last_name_cont: q, m: "or").result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :email, as: :text
    field :first_name, as: :text
    field :last_name, as: :text
    field :phone, as: :text
    field :status, as: :select, enum: ::User.statuses
    field :plan_tier, as: :select, enum: ::User.plan_tiers
    field :discarded_at, as: :date_time
  end
end
