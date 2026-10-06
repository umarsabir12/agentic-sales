class DashboardController < ApplicationController
  RANGES = [ 7, 14, 30 ].freeze
  RESOLUTION_WINDOW = 30.days

  def show
    @range = params[:range].to_i.presence_in(RANGES) || 14

    load_attention
    load_stats
    @replies_by_day = replies_by_day(@range)
    @live_conversations = Conversation.open.includes(:contact, :messages)
      .order(Arel.sql("CASE WHEN conversations.status = #{Conversation.statuses[:human_active]} THEN 0 ELSE 1 END"))
      .recent.limit(5)
    @active_tickets = Ticket.active.includes(:contact, :assignee).order(priority: :desc, created_at: :desc).limit(8)
    @team = User.order(:name)
  end

  private
    def load_attention
      @needs_human = Conversation.human_active.count
      @unowned_hot_tickets = Ticket.active.where(assignee_id: nil, priority: %i[ high urgent ]).count
    end

    def load_stats
      today = Time.current.all_day
      @conversations_today = Message.inbound.where(created_at: today).distinct.count(:conversation_id)
      @messages_today = Message.inbound.where(created_at: today).count
      @new_contacts_this_week = Contact.where(created_at: Time.current.all_week).count

      recent = Conversation.where(id: Message.inbound.where(created_at: RESOLUTION_WINDOW.ago..).select(:conversation_id))
      @recent_conversations = recent.count
      @ai_only_conversations = recent.where.not(id: Message.sent_by_staff.select(:conversation_id)).where.not(status: :human_active).count
      @ai_resolution_rate = @recent_conversations.zero? ? 0 : (@ai_only_conversations * 100.0 / @recent_conversations).round

      @active_tickets_count = Ticket.active.count
      @hot_tickets = Ticket.active.where(priority: %i[ high urgent ]).count
      @unassigned_tickets = Ticket.active.where(assignee_id: nil).count

      month = Time.current.all_month
      @won_value = Ticket.won.where(closed_at: month).sum(:value)
      @won_count = Ticket.won.where(closed_at: month).count
      @lost_count = Ticket.lost.where(closed_at: month).count
      @pipeline_value = Ticket.active.sum(:value)
    end

    # [[date, ai_replies, team_replies], ...] for the last `days` days.
    def replies_by_day(days)
      dates = ((days - 1).days.ago.to_date..Date.current)
      replies = Message.outbound.where(sender_type: %i[ ai staff ], created_at: dates.first.beginning_of_day..)
        .pluck(:created_at, :sender_type)
        .group_by { |created_at, _| created_at.to_date }

      dates.map do |date|
        senders = Array(replies[date]).map(&:last).tally
        [ date, senders.fetch("ai", 0), senders.fetch("staff", 0) ]
      end
    end
end
