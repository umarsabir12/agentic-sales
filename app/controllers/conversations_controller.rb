class ConversationsController < ApplicationController
  before_action :set_conversation, except: %i[ index new create ]

  def index
    @status = params[:status].presence_in(Conversation.statuses.keys)
    @conversations = Conversation.includes(:contact, :assigned_user).recent
    @conversations = @status ? @conversations.where(status: @status) : @conversations.open
  end

  def new
    @outreach = Outreach.new(phone: params[:phone], template_id: params[:template_id])
  end

  def create
    @outreach = Outreach.new(outreach_params.merge(user: current_user))

    if @outreach.save
      redirect_to @outreach.conversation, notice: "Template message queued for sending."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @messages = @conversation.messages.includes(:user)
    @tickets = @conversation.tickets.order(created_at: :desc)
  end

  def take_over
    @conversation.take_over!(current_user)
    redirect_back_or_to @conversation, notice: "You've taken over this conversation. The AI is paused."
  end

  def hand_back
    @conversation.hand_back_to_ai!
    redirect_back_or_to @conversation, notice: "Conversation handed back to the AI."
  end

  def close
    @conversation.close!
    redirect_to @conversation, notice: "Conversation closed."
  end

  def reopen
    @conversation.reopen!
    redirect_to @conversation, notice: "Conversation reopened."
  end

  private
    def outreach_params
      params.expect(outreach: [ :phone, :name, :template_id, template_params: [] ])
    end

    def set_conversation
      @conversation = Conversation.includes(:contact).find(params[:id])
    end
end
