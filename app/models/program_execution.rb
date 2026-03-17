class ProgramExecution < ApplicationRecord
  belongs_to :user
  belongs_to :workout
  has_many :exercise_logs, dependent: :destroy

  accepts_nested_attributes_for :exercise_logs
end
