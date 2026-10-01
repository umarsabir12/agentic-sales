class ConversationsController < ApplicationController
  before_action :set_conversation, except: :index

  def index
    @status = params[:status].presence_in(Conversation.statuses.keys)
    @conversations = Conversation.includes(:contact, :assigned_user).recent
    @conversations = @status ? @conversations.where(status: @status) : @conversations.open
  end

  def show
    @messages = @conversation.messages.includes(:user)
    @tickets = @conversation.tickets.order(created_at: :desc)
  end

  def take_over
    @conversation.take_over!(current_user)
    redirect_to @conversation, notice: "You've taken over this conversation. The AI is paused."
  end

  def hand_back
    @conversation.hand_back_to_ai!
    redirect_to @conversation, notice: "Conversation handed back to the AI."
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
    def set_conversation
      @conversation = Conversation.includes(:contact).find(params[:id])
    end
end
