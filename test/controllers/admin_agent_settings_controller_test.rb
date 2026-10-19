require "test_helper"

class AdminAgentSettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "admins edit the agent's instructions" do
    sign_in users(:admin)
    get edit_admin_agent_path
    assert_response :success

    patch admin_agent_path, params: { agent_setting: { business_name: "Tronsit", instructions: "We sell solar.", effort: "low", enabled: "1", reply_delay_seconds: 3 } }
    assert_redirected_to edit_admin_agent_path
    assert_equal "low", AgentSetting.current.effort
  end

  test "agents cannot change the AI settings" do
    sign_in users(:agent)
    get edit_admin_agent_path
    assert_redirected_to root_path
  end
end
