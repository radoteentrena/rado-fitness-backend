require "administrate/field/base"

class ReadStatusField < Administrate::Field::Base
  def to_s
    data.present? ? "Read ✓" : "Not read"
  end
end
