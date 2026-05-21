require "administrate/base_dashboard"

class CoachScheduleDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:          Field::Number,
    day_of_week: Field::Select.with_options(
                   searchable: false,
                   collection: CoachSchedule::DAYS.map.with_index { |name, i| [name, i] }
                 ),
    start_hour:  Field::Number,
    end_hour:    Field::Number,
    active:      Field::Boolean,
    created_at:  Field::DateTime,
    updated_at:  Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[day_of_week start_hour end_hour active].freeze

  SHOW_PAGE_ATTRIBUTES = %i[id day_of_week start_hour end_hour active created_at updated_at].freeze

  FORM_ATTRIBUTES = %i[day_of_week start_hour end_hour active].freeze

  def display_resource(coach_schedule)
    "#{coach_schedule.day_name} #{coach_schedule.start_hour}:00–#{coach_schedule.end_hour}:00"
  end
end
