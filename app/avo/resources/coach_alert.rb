class Avo::Resources::CoachAlert < Avo::BaseResource
  self.title = :message
  self.includes = []
  self.search = {
    query: -> { query.ransack(id_eq: q, message_cont: q, m: "or").result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :user, as: :belongs_to
    field :category, as: :badge, options: {
      success: :check_in,
      warning: :missed_workout,
      danger: :weight_spike,
      info: :low_compliance
    }
    field :status, as: :badge, options: {
      success: :resolved,
      warning: :pending,
      neutral: :dismissed
    }
    field :message, as: :textarea
    field :action_taken, as: :textarea, hide_on: :index
    field :created_at, as: :date, time: true
  end
end
