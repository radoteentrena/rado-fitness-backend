require "test_helper"

class PromoLinkTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @user.update!(promoter: true)
  end

  test "generates a unique 8-char uppercase code before create" do
    link = PromoLink.create!(user: @user, label: "Instagram")
    assert_match(/\A[A-Z0-9]{8}\z/, link.code)
  end

  test "code is unique" do
    link1 = PromoLink.create!(user: @user, label: "Instagram")
    link2 = PromoLink.create!(user: @user, label: "TikTok")
    assert_not_equal link1.code, link2.code
  end

  test "active scope returns only active links" do
    active   = PromoLink.create!(user: @user, label: "A")
    inactive = PromoLink.create!(user: @user, label: "B", active: false)
    assert_includes PromoLink.active, active
    assert_not_includes PromoLink.active, inactive
  end

  test "requires label" do
    link = PromoLink.new(user: @user)
    assert_not link.valid?
    assert link.errors[:label].any?
  end

  test "full_url includes promo param" do
    link = PromoLink.create!(user: @user, label: "IG")
    assert_includes link.full_url, "promo=#{link.code}"
  end
end
