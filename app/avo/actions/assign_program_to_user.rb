class Avo::Actions::AssignProgramToUser < Avo::BaseAction
  self.name = "Assign to User"
  self.visible = -> { view == :show }

  def fields
    field :user_id, as: :select, options: User.order(:first_name).map { |u| [u.name, u.id] }, required: true, label: "Select User"
  end

  def handle(**args)
    program = args[:models].first
    user_id = args[:fields][:user_id]
    user = User.find(user_id)

    begin
      new_program = program.assign_to_user(user)
      succeed "Program '#{new_program.name}' assigned to #{user.name}!"
    rescue => e
      error "Failed to assign program: #{e.message}"
    end
  end
end
