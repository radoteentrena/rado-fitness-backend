require "administrate/base_dashboard"

class RoutineExerciseDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    day_name: Field::String,
    day_number: Field::Number,
    exercise: Field::BelongsTo,
    instructions: Field::Text,
    load: Field::String,
    order_index: Field::Number,
    reps: Field::String,
    rest_seconds: Field::Number,
    rir: Field::String,
    routine: Field::BelongsTo,
    sets: Field::Number,
    sub_option: Field::Number,
    warmup: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    day_name
    day_number
    exercise
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    day_name
    day_number
    exercise
    instructions
    load
    order_index
    reps
    rest_seconds
    rir
    routine
    sets
    sub_option
    warmup
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    day_name
    day_number
    exercise
    instructions
    load
    order_index
    reps
    rest_seconds
    rir
    routine
    sets
    sub_option
    warmup
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

  # Overwrite this method to customize how routine exercises are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(routine_exercise)
  #   "RoutineExercise ##{routine_exercise.id}"
  # end
end
