require "administrate/field/base"

class UserNameField < Administrate::Field::Base
  def to_s
    "#{resource.first_name} #{resource.last_name[0]}."
  end
end
