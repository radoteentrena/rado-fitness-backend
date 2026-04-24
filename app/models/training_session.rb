class TrainingSession < ApplicationRecord
  belongs_to :user
  belongs_to :program
  belongs_to :phase
  belongs_to :routine
  belongs_to :workout
  has_many :exercise_logs, dependent: :destroy

  enum :status, { pending: 0, in_progress: 1, completed: 2, skipped: 3 }

  validates :cycle_number, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :session_number, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :started_at, presence: true, if: -> { in_progress? || completed? }

  def self.current_for(user)
    where(user: user, status: [ statuses[:pending], statuses[:in_progress] ])
      .order(created_at: :asc)
      .first
  end
end
