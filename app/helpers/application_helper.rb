module ApplicationHelper
  BADGE_COLORS = {
    # conversation status
    "ai_active" => "bg-violet-50 text-violet-700",
    "human_active" => "bg-amber-50 text-amber-700",
    "closed" => "bg-gray-100 text-gray-600",
    # ticket status
    "open" => "bg-brand-50 text-brand-700",
    "in_progress" => "bg-amber-50 text-amber-700",
    "won" => "bg-green-50 text-green-700",
    "lost" => "bg-gray-100 text-gray-600",
    # ticket priority
    "low" => "bg-gray-100 text-gray-600",
    "medium" => "bg-sky-50 text-sky-700",
    "high" => "bg-orange-50 text-orange-700",
    "urgent" => "bg-red-50 text-red-700",
    # template status (as reported by Meta)
    "APPROVED" => "bg-green-50 text-green-700",
    "PENDING" => "bg-amber-50 text-amber-700",
    "IN_APPEAL" => "bg-amber-50 text-amber-700",
    "REJECTED" => "bg-red-50 text-red-700",
    "PAUSED" => "bg-gray-100 text-gray-600",
    "DISABLED" => "bg-gray-100 text-gray-600"
  }.freeze

  BADGE_LABELS = { "ai_active" => "AI", "human_active" => "Human", "IN_APPEAL" => "In appeal" }.freeze

  def badge(value)
    tag.span BADGE_LABELS.fetch(value.to_s, value.to_s.humanize),
      class: "inline-flex items-center rounded px-2 py-0.5 text-xs font-medium #{BADGE_COLORS.fetch(value.to_s, "bg-gray-100 text-gray-600")}"
  end

  def nav_link(label, path, active:, count: nil)
    link_to path, class: [ "nav-pill", ("nav-pill-active" if active) ], aria: { current: ("page" if active) } do
      safe_join([ label,
        (tag.span(count, class: "inline-flex h-4 min-w-4 items-center justify-center rounded-full bg-orange-500 px-1 text-[10px] font-semibold text-white") if count.to_i.positive?) ].compact)
    end
  end

  def money(amount)
    return "—" if amount.nil?

    "#{Rails.configuration.x.currency} #{number_with_delimiter(amount.to_d.round)}"
  end

  # "6 min", "6 h", "4 d" — compact relative time for dense lists.
  def short_time_ago(time)
    return "" unless time

    seconds = (Time.current - time).to_i
    if seconds < 60 then "now"
    elsif seconds < 3600 then "#{seconds / 60} min"
    elsif seconds < 86_400 then "#{seconds / 3600} h"
    else "#{seconds / 86_400} d"
    end
  end

  def greeting
    case Time.current.hour
    when 5...12 then "Good morning"
    when 12...17 then "Good afternoon"
    else "Good evening"
    end
  end

  def current_theme
    cookies[:theme] == "dark" ? "dark" : "light"
  end

  # <option>s for approved templates, carrying what the template-picker Stimulus controller needs.
  def template_options(templates, selected_id)
    options = templates.map do |t|
      tag.option("#{t.name} (#{t.language})", value: t.id, selected: t.id == selected_id,
        data: { body: t.render, variables: t.variable_count })
    end
    safe_join([ tag.option("Select a template", value: "") ] + options)
  end

  def enum_options(model, attribute)
    model.public_send(attribute.to_s.pluralize).keys.map { |k| [ k.humanize, k ] }
  end
end
