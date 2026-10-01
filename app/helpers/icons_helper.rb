# Outline icons from Tabler Icons (MIT), https://tabler.io/icons
module IconsHelper
  ICONS = {
    dashboard: [ "M5 12l-2 0l9 -9l9 9l-2 0", "M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-7", "M9 21v-6a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v6" ],
    inbox: [ "M8 9h8", "M8 13h6", "M18 4a3 3 0 0 1 3 3v8a3 3 0 0 1 -3 3h-5l-5 3v-3h-2a3 3 0 0 1 -3 -3v-8a3 3 0 0 1 3 -3h12z" ],
    ticket: [ "M15 5l0 2", "M15 11l0 2", "M15 17l0 2", "M5 5h14a2 2 0 0 1 2 2v3a2 2 0 0 0 0 4v3a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-3a2 2 0 0 0 0 -4v-3a2 2 0 0 1 2 -2" ],
    contacts: [ "M20 6v12a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2h10a2 2 0 0 1 2 2z", "M10 16h6", "M11 11a2 2 0 1 0 4 0a2 2 0 1 0 -4 0", "M4 8h3", "M4 12h3", "M4 16h3" ],
    team: [ "M5 7a4 4 0 1 0 8 0a4 4 0 1 0 -8 0", "M3 21v-2a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v2", "M16 3.13a4 4 0 0 1 0 7.75", "M21 21v-2a4 4 0 0 0 -3 -3.85" ],
    robot: [ "M6 6a2 2 0 0 1 2 -2h8a2 2 0 0 1 2 2v4a2 2 0 0 1 -2 2h-8a2 2 0 0 1 -2 -2z", "M12 2v2", "M9 12v9", "M15 12v9", "M5 16l4 -2", "M15 14l4 2", "M9 18h6", "M10 8v.01", "M14 8v.01" ],
    user_check: [ "M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0", "M6 21v-2a4 4 0 0 1 4 -4h4", "M15 19l2 2l4 -4" ],
    user_plus: [ "M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0", "M16 19h6", "M19 16v6", "M6 21v-2a4 4 0 0 1 4 -4h4" ],
    trophy: [ "M8 21l8 0", "M12 17l0 4", "M7 4l10 0", "M17 4v8a5 5 0 0 1 -10 0v-8", "M3 9a2 2 0 1 0 4 0a2 2 0 1 0 -4 0", "M17 9a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" ],
    message_in: [ "M8 9h8", "M8 13h6", "M9 18h-3a3 3 0 0 1 -3 -3v-8a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v8a3 3 0 0 1 -3 3h-3l-3 3l-3 -3z" ],
    plus: [ "M12 5l0 14", "M5 12l14 0" ],
    search: [ "M3 10a7 7 0 1 0 14 0a7 7 0 1 0 -14 0", "M21 21l-6 -6" ],
    logout: [ "M14 8v-2a2 2 0 0 0 -2 -2h-7a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h7a2 2 0 0 0 2 -2v-2", "M9 12h12l-3 -3", "M18 15l3 -3" ],
    chevron_down: [ "M6 9l6 6l6 -6" ],
    pencil: [ "M4 20h4l10.5 -10.5a2.828 2.828 0 1 0 -4 -4l-10.5 10.5v4", "M13.5 6.5l4 4" ],
    trash: [ "M4 7l16 0", "M10 11l0 6", "M14 11l0 6", "M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12", "M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" ],
    send: [ "M10 14l11 -11", "M21 3l-6.5 18a.55 .55 0 0 1 -1 0l-3.5 -7l-7 -3.5a.55 .55 0 0 1 0 -1l18 -6.5" ]
  }.freeze

  def icon(name, size: 18, css: nil)
    paths = ICONS.fetch(name).map { |d| tag.path(d: d) }
    tag.svg safe_join(paths), xmlns: "http://www.w3.org/2000/svg", width: size, height: size, viewBox: "0 0 24 24",
      fill: "none", stroke: "currentColor", "stroke-width": 1.75, "stroke-linecap": "round", "stroke-linejoin": "round",
      class: [ "shrink-0", css ], "aria-hidden": true
  end
end
