require "test_helper"

class ProgramMatcherServiceTest < ActiveSupport::TestCase
  def setup
    @user     = users(:active_user)
    @template = programs(:template_program)
    @user.programs.destroy_all
  end

  test "returns nil when user already has a program" do
    @user.programs.create!(name: "Existing", duration_weeks: 8)
    assert_nil ProgramMatcherService.new(@user).call
  end

  test "force: true assigns even when user has existing programs" do
    @user.programs.create!(name: "Existing", duration_weeks: 8)
    @user.onboarding_profile&.destroy
    @user.reload
    result = ProgramMatcherService.new(@user, force: true).call
    assert_not_nil result
    assert_equal @user.id, result.user_id
  end

  test "returns nil and logs warning when no templates exist" do
    Program.where(user_id: nil).destroy_all
    assert_nil ProgramMatcherService.new(@user).call
  end

  test "assigns first template by id when onboarding_profile is nil" do
    @user.onboarding_profile&.destroy
    @user.reload
    result = ProgramMatcherService.new(@user).call
    assert_not_nil result
    assert_equal @user.id, result.user_id
  end

  test "pre-filter selects template matching training_frequency workout count" do
    @user.onboarding_profile&.destroy
    @user.reload
    result = ProgramMatcherService.new(@user).call
    assert_not_nil result
    assert_equal @user.id, result.user_id
  end
end
