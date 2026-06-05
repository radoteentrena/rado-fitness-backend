require "test_helper"

class PromoConversionTest < ActiveSupport::TestCase
  def setup
    @promoter = users(:one)
    @promoter.update!(promoter: true)
    @referred  = users(:two)
    @link      = PromoLink.create!(user: @promoter, label: "IG")
    @sub       = subscriptions(:one)
    @sub.update!(user: @referred)
  end

  test "pending scope returns conversions without paid_at" do
    conversion = PromoConversion.create!(
      promo_link: @link, referred_user: @referred, subscription: @sub,
      plan_tier: "medium", currency: "USD",
      full_price_cents: 15_000, paid_amount_cents: 11_250,
      promoter_earnings_cents: 3_750
    )
    assert_includes PromoConversion.pending, conversion
    assert_not_includes PromoConversion.paid, conversion
  end

  test "paid scope returns conversions with paid_at set" do
    conversion = PromoConversion.create!(
      promo_link: @link, referred_user: @referred, subscription: @sub,
      plan_tier: "medium", currency: "USD",
      full_price_cents: 15_000, paid_amount_cents: 11_250,
      promoter_earnings_cents: 3_750, paid_at: Time.current
    )
    assert_includes PromoConversion.paid, conversion
    assert_not_includes PromoConversion.pending, conversion
  end

  test "referred_user_id must be unique" do
    PromoConversion.create!(
      promo_link: @link, referred_user: @referred, subscription: @sub,
      plan_tier: "medium", currency: "USD",
      full_price_cents: 15_000, paid_amount_cents: 11_250,
      promoter_earnings_cents: 3_750
    )
    duplicate = PromoConversion.new(
      promo_link: @link, referred_user: @referred, subscription: @sub,
      plan_tier: "medium", currency: "USD",
      full_price_cents: 15_000, paid_amount_cents: 11_250,
      promoter_earnings_cents: 3_750
    )
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end
end
