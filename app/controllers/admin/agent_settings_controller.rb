class Admin::AgentSettingsController < Admin::BaseController
  def edit
    @settings = AgentSetting.current
  end

  def update
    @settings = AgentSetting.current

    if @settings.update(settings_params)
      redirect_to edit_admin_agent_path, notice: "AI agent settings saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def settings_params
      params.expect(agent_setting: %i[ enabled business_name instructions effort reply_delay_seconds ])
    end
end
