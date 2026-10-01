class DashboardController < ApplicationController
  CHART_DAYS = 14

  def show
    @open_conversations = Conversation.open.count
    @ai_conversations = Conversation.ai_active.count
    @needs_human = Conversation.human_active.count
    @active_tickets = Ticket.active.count
    @hot_tickets = Ticket.active.where(priority: %i[ high urgent ]).count
    @won_this_month = Ticket.won.where(closed_at: Time.current.all_month).count
    @lost_this_month = Ticket.lost.where(closed_at: Time.current.all_month).count

    today = Time.current.all_day
    week = Time.current.all_week
    @messages_today = Message.inbound.where(created_at: today).count
    @ai_replies_today = Message.sent_by_ai.where(created_at: today).count
    @new_contacts_this_week = Contact.where(created_at: week).count
    @tickets_this_week = Ticket.where(created_at: week).count
    @ai_tickets_this_week = Ticket.source_ai.where(created_at: week).count

    @daily_messages = daily_inbound_messages
    @recent_conversations = Conversation.open.includes(:contact).recent.limit(6)
    @recent_tickets = Ticket.active.includes(:contact, :assignee).order(created_at: :desc).limit(6)
  end

  private
    def daily_inbound_messages
      range = (CHART_DAYS - 1).days.ago.to_date..Date.current
      counts = Message.inbound.where(created_at: range.first.beginning_of_day..).pluck(:created_at).map(&:to_date).tally
      range.map { |day| [ day, counts.fetch(day, 0) ] }
    end
end
