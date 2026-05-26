class DailyMetric < ApplicationRecord
  belongs_to :user
  belongs_to :user_dietary_plan, optional: true

  before_validation :assign_to_active_plan, on: :create
  before_save  :process_before_save
  after_save   :process_after_save

  private

  def assign_to_active_plan
    self.user_dietary_plan ||= user.user_dietary_plans.active.last
  end

  def process_before_save
    Processor.new(self).run
  end

  def process_after_save
    Processor.new(self).run_after_save
  end
end
