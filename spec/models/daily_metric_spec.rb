require 'rails_helper'

RSpec.describe DailyMetric, type: :model do
  describe 'dual compliance logic' do
    let(:user) { User.create!(first_name: 'Test', last_name: 'User', email: 'test@example.com', password: 'password') }
    let!(:plan) { UserDietaryPlan.create!(user: user, calories_target: 2000, protein_target: 150, active: true) }

    # No mocking needed, assign_to_active_plan callback will find the plan

    context 'consistency (compliant)' do
      it 'is true when calories are logged' do
        metric = DailyMetric.create!(user: user, calories_consumed: 500, date_logged: Date.today)
        expect(metric.compliant).to be true
      end

      it 'is true when protein is logged' do
        metric = DailyMetric.create!(user: user, protein_consumed: 10, date_logged: Date.today)
        expect(metric.compliant).to be true
      end

      it 'is false when nothing is logged' do
        metric = DailyMetric.create!(user: user, steps: 5000, date_logged: Date.today) # Steps don't count for nutritional compliance
        expect(metric.compliant).to be false
      end
    end

    context 'accuracy (on_target)' do
      it 'is true when within 10% range' do
        # Target: 2000 cal (1800-2200), 150g protein (135-165)
        metric = DailyMetric.create!(
          user: user,
          calories_consumed: 2100,
          protein_consumed: 140,
          date_logged: Date.today
        )
        expect(metric.on_target).to be true
      end

      it 'is false when calories are off' do
        metric = DailyMetric.create!(
          user: user,
          calories_consumed: 2300, # Too high
          protein_consumed: 140,
          date_logged: Date.today
        )
        expect(metric.on_target).to be false
      end

      it 'is false when protein is off' do
        metric = DailyMetric.create!(
          user: user,
          calories_consumed: 2000,
          protein_consumed: 100, # Too low
          date_logged: Date.today
        )
        expect(metric.on_target).to be false
      end

      it 'is false if no plan exists' do
        user_no_plan = User.create!(first_name: 'No', last_name: 'Plan', email: 'noplan@test.com', password: 'password')
        metric = DailyMetric.create!(
          user: user_no_plan,
          calories_consumed: 2000,
          protein_consumed: 150,
          date_logged: Date.today
        )
        expect(metric.on_target).to be false
      end
    end
  end
end
