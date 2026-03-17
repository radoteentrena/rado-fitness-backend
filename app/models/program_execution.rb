class ProgramExecution < ApplicationRecord
  belongs_to :user
  belongs_to :workout
  belongs_to :training_session, optional: true
  has_many :exercise_logs, dependent: :destroy

  accepts_nested_attributes_for :exercise_logs
end
