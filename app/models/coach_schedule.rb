class CoachSchedule < ApplicationRecord
  DAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  validates :day_of_week, presence: true,
                          inclusion: { in: 0..6 },
                          uniqueness: true
  validates :start_hour, presence: true, inclusion: { in: 0..23 }
  validates :end_hour, presence: true, inclusion: { in: 1..24 }
  validate :end_after_start

  def day_name
    DAYS[day_of_week]
  end

  private

  def end_after_start
    return unless start_hour && end_hour
    errors.add(:end_hour, "must be after start_hour") unless end_hour > start_hour
  end
end
