require "administrate/field/base"

class ConversationUserField < Administrate::Field::Base
  def to_s
    "#{resource.first_name} #{resource.last_name[0]}."
  end

  def resource
    data
  end
end
