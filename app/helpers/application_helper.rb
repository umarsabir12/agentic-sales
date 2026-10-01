module ApplicationHelper
  BADGE_COLORS = {
    # conversation status
    "ai_active" => "bg-brand-50 text-brand-700",
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
    "urgent" => "bg-red-50 text-red-700"
  }.freeze

  BADGE_LABELS = { "ai_active" => "AI", "human_active" => "Human" }.freeze

  def badge(value)
    tag.span BADGE_LABELS.fetch(value.to_s, value.to_s.humanize),
      class: "inline-flex items-center rounded px-2 py-0.5 text-xs font-medium #{BADGE_COLORS.fetch(value.to_s, "bg-gray-100 text-gray-600")}"
  end

  def nav_link(label, path, icon_name:, active:, count: nil)
    link_to path, class: [ "flex items-center gap-2 border-b-2 px-1 py-3.5 text-sm",
      active ? "border-brand-600 text-ink font-medium" : "border-transparent text-gray-500 hover:text-ink" ] do
      safe_join([ icon(icon_name), label,
        (tag.span(count, class: "rounded-full bg-amber-100 px-1.5 text-[11px] font-semibold text-amber-800") if count.to_i.positive?) ].compact)
    end
  end

  def enum_options(model, attribute)
    model.public_send(attribute.to_s.pluralize).keys.map { |k| [ k.humanize, k ] }
  end
end
