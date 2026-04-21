require "test_helper"

class Admin::ProgramChatControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @program = programs(:user_program)
    ENV["ADMIN_EMAILS"] = users(:admin_user).email
    sign_in users(:admin_user)
  end

  teardown do
    ENV["ADMIN_EMAILS"] = nil
  end

  test "show creates a new AiConversation and renders" do
    assert_difference "AiConversation.count", 1 do
      get admin_program_chat_path(@program)
    end
    assert_response :success
  end

  test "show reuses existing active conversation" do
    AiConversation.create!(
      program:        @program,
      user:           @program.user,
      status:         "active",
      objectives:     "Chat de programa: #{@program.name}",
      generated_data: {}
    )
    assert_no_difference "AiConversation.count" do
      get admin_program_chat_path(@program)
    end
    assert_response :success
  end

  test "message returns turbo stream on Gemini failure" do
    AiConversation.create!(
      program:        @program,
      user:           @program.user,
      status:         "active",
      objectives:     "Chat de programa: #{@program.name}",
      generated_data: { "routines" => [] }
    )
    post message_admin_program_chat_path(@program),
         params:  { message: "Aumenta las series" },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "turbo-stream", response.body
  end

  test "apply patches program and returns turbo stream" do
    AiConversation.create!(
      program:        @program,
      user:           @program.user,
      status:         "active",
      objectives:     "Chat de programa: #{@program.name}",
      generated_data: { "routines" => [] }
    )

    post apply_admin_program_chat_path(@program),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "turbo-stream", response.body
  end
end
