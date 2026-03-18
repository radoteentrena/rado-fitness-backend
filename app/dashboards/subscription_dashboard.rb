require "administrate/base_dashboard"

class SubscriptionDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:                   Field::Number,
    user:                 Field::BelongsTo,
    processor:            Field::Select.with_options(
                            searchable: false,
                            collection: ->(f) { f.resource.class.processors.keys }
                          ),
    plan_tier:            Field::Select.with_options(
                            searchable: false,
                            collection: ->(f) { f.resource.class.plan_tiers.keys }
                          ),
    status:               Field::Select.with_options(
                            searchable: false,
                            collection: ->(f) { f.resource.class.statuses.keys }
                          ),
    currency:             Field::String,
    amount_cents:         Field::Number,
    external_id:          Field::String,
    current_period_end:   Field::DateTime,
    cancel_at_period_end: Field::Boolean,
    canceled_at:          Field::DateTime,
    created_at:           Field::DateTime,
    updated_at:           Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[user plan_tier processor status current_period_end].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id user processor plan_tier status currency amount_cents
    external_id current_period_end cancel_at_period_end canceled_at
    created_at updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[].freeze

  COLLECTION_FILTERS = {
    active:      ->(resources) { resources.where(status: :active) },
    past_due:    ->(resources) { resources.where(status: :past_due) },
    stripe:      ->(resources) { resources.where(processor: :stripe) },
    mercadopago: ->(resources) { resources.where(processor: :mercadopago) }
  }.freeze

  def display_resource(subscription)
    "#{subscription.user&.name} — #{subscription.plan_tier&.humanize}"
  end
end
