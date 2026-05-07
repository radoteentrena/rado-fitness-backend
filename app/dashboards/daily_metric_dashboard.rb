require "administrate/base_dashboard"

class DailyMetricDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    ai_parsed_json: Field::String.with_options(searchable: false),
    calories_consumed: Field::Number,
    compliant: Field::Boolean,
    date_logged: Field::Date,
    on_target: Field::Boolean,
    protein_consumed: Field::Number,
    fats: Field::Number,
    carbs: Field::Number,
    raw_message_content: Field::Text,
    user: Field::BelongsTo,
    user_dietary_plan: Field::BelongsTo,
    weight: Field::Number.with_options(decimals: 2),
    workout_completed: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    ai_parsed_json
    calories_consumed
    compliant
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    ai_parsed_json
    calories_consumed
    compliant
    date_logged
    on_target
    protein_consumed
    fats
    carbs
    raw_message_content
    user
    user_dietary_plan
    weight
    workout_completed
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    ai_parsed_json
    calories_consumed
    compliant
    date_logged
    on_target
    protein_consumed
    fats
    carbs
    raw_message_content
    user
    user_dietary_plan
    weight
    workout_completed
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how daily metrics are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(daily_metric)
  #   "DailyMetric ##{daily_metric.id}"
  # end
end
