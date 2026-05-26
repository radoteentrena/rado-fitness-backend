require "administrate/base_dashboard"

class BookDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:               Field::Number,
    title:            Field::String,
    ingestion_status: Field::String,
    created_at:       Field::DateTime,
    updated_at:       Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[title ingestion_status created_at].freeze
  SHOW_PAGE_ATTRIBUTES  = %i[title ingestion_status created_at].freeze
  FORM_ATTRIBUTES       = %i[title].freeze
end
