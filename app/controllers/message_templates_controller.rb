class MessageTemplatesController < ApplicationController
  before_action :require_admin, only: %i[ new create destroy ]
  before_action :set_template, only: %i[ show destroy ]

  def index
    @templates = MessageTemplate.alphabetical
  end

  def show
  end

  def new
    @template = MessageTemplate.new(category: "UTILITY", language: "en_US")
  end

  def create
    @template = MessageTemplate.new(template_params)

    if @template.submit!
      redirect_to @template, notice: "Template submitted to Meta for review. Approval usually takes a few minutes, sometimes up to 24 hours."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @template.delete_remotely!
    redirect_to message_templates_path, notice: "Template deleted.", status: :see_other
  rescue Whatsapp::Client::Error => e
    redirect_to @template, alert: "Meta couldn't delete the template: #{e.message}"
  end

  def sync
    count = MessageTemplate.sync!
    redirect_to message_templates_path, notice: "Synced #{count} #{"template".pluralize(count)} from Meta."
  rescue Whatsapp::Client::Error => e
    redirect_to message_templates_path, alert: "Sync failed: #{e.message}"
  end

  private
    def set_template
      @template = MessageTemplate.find(params[:id])
    end

    def template_params
      params.expect(message_template: [ :name, :language, :category, :header_text, :body, :footer, :quick_replies, body_examples: [], url_button: %i[ text url ] ])
    end

    def require_admin
      redirect_to message_templates_path, alert: "Only admins can create or delete templates." unless current_user.admin?
    end
end
