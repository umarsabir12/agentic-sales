class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[ show edit update destroy ]

  def index
    @tickets = Ticket.includes(:contact, :assignee).order(priority: :desc, created_at: :desc)
    @tickets = @tickets.where(assignee: current_user) if params[:mine].present?
    @tickets_by_status = @tickets.group_by(&:status)
  end

  def show
  end

  def new
    conversation = Conversation.find_by(id: params[:conversation_id])
    @ticket = Ticket.new(conversation: conversation, contact: conversation&.contact, assignee: current_user, source: :manual)
  end

  def create
    @ticket = Ticket.new(ticket_params.merge(source: :manual))

    if @ticket.save
      redirect_to @ticket, notice: "Ticket created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ticket.update(ticket_params)
      return redirect_back_or_to(@ticket, notice: "Ticket updated.") if params[:back].present?

      redirect_to @ticket, notice: "Ticket updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ticket.destroy!
    redirect_to tickets_path, notice: "Ticket deleted.", status: :see_other
  end

  private
    def set_ticket
      @ticket = Ticket.find(params[:id])
    end

    def ticket_params
      params.expect(ticket: %i[ title summary product_interest budget value status priority contact_id conversation_id assignee_id ])
    end
end
