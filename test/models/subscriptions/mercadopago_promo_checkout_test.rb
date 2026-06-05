require "test_helper"
require "minitest/mock"

class Subscriptions::MercadoPagoPromoCheckoutTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @promoter = users(:two)
    @promoter.update!(promoter: true)
    @promo_link = PromoLink.create!(user: @promoter, label: "IG")
  end

  test "rejects invalid plan tiers" do
    result = Subscriptions::MercadoPagoPromoCheckout.new(@user, :basic, @promo_link).call
    assert_equal false, result[:success]
    assert_match /no permitido/, result[:error]
  end

  test "creates a pending subscription record on successful MP response" do
    mock_sdk = Minitest::Mock.new
    mock_preference = Minitest::Mock.new
    mock_sdk.expect(:preference, mock_preference)
    mock_preference.expect(:create, { status: 201, response: { "id" => "pref_123", "init_point" => "https://mp.com/pay" } }, [Hash])

    Mercadopago::SDK.stub(:new, mock_sdk) do
      assert_difference "Subscription.count", 1 do
        result = Subscriptions::MercadoPagoPromoCheckout.new(@user, :medium, @promo_link).call
        assert result[:success]
        assert_equal "https://mp.com/pay", result[:redirect_url]
      end
    end

    sub = Subscription.last
    assert sub.pending?
    assert sub.one_time?
    assert sub.monthly?
    assert_equal "USD", sub.currency
    assert_equal @promo_link, sub.promo_link
  end

  test "returns failure hash on MP error" do
    mock_sdk = Minitest::Mock.new
    mock_preference = Minitest::Mock.new
    mock_sdk.expect(:preference, mock_preference)
    mock_preference.expect(:create, { status: 400, response: {} }, [Hash])

    Mercadopago::SDK.stub(:new, mock_sdk) do
      result = Subscriptions::MercadoPagoPromoCheckout.new(@user, :medium, @promo_link).call
      assert_equal false, result[:success]
    end
  end
end
