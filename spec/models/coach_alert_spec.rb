require "rails_helper"

RSpec.describe CoachAlert, type: :model do
  describe "payment_failed category" do
    it "can be created with payment_failed category" do
      user = create(:user)
      alert = CoachAlert.new(
        user: user,
        category: :payment_failed,
        message: "Payment failed for subscription",
        status: :pending
      )
      expect(alert).to be_valid
    end
  end
end
