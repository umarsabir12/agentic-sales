class MessagesController < ApplicationController
  def create
    @conversation = Conversation.find(params[:conversation_id])
    return send_template if params[:outreach].present?

    unless @conversation.within_service_window?
      return redirect_to @conversation, alert: "The 24-hour reply window has expired. Only template messages can be sent."
    end

    @message = @conversation.messages.build(message_params.merge(direction: :outbound, sender_type: :staff, user: current_user))

    if @message.save
      # A human replying pauses the AI on this conversation.
      @conversation.take_over!(current_user) unless @conversation.human_active?
      redirect_to @conversation
    else
      redirect_to @conversation, alert: @message.errors.full_messages.to_sentence
    end
  end

  private
    def send_template
      outreach = Outreach.new(params.expect(outreach: [ :template_id, template_params: [] ]).merge(conversation: @conversation, user: current_user))

      if outreach.save
        redirect_to @conversation, notice: "Template message queued for sending."
      else
        redirect_to @conversation, alert: outreach.errors.full_messages.to_sentence
      end
    end

    def message_params
      params.expect(message: [ :body ])
    end
end
