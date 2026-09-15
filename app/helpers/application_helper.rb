module ApplicationHelper
  def space_section
    {
      "aliens" => { number: "01", category: "Species database", singular: "Alien", file: "Species", description: "Discover the extraordinary. Explore lifeforms from across the known universe.", empty: "No lifeforms detected", icon: "alien" },
      "planets" => { number: "02", category: "Planetary atlas", singular: "Planet", file: "World", description: "Every world holds a story. Chart the homeworlds of our interstellar neighborhood.", empty: "Uncharted territory", icon: "planet" },
      "powers" => { number: "03", category: "Ability archive", singular: "Power", file: "Ability", description: "Beyond the ordinary. Explore the extraordinary abilities that shape the galaxy.", empty: "No energy signatures detected", icon: "power" }
    }.fetch(controller_name, { number: "00", category: "Interstellar database", singular: "Record", file: "Record", icon: "planet" })
  end

  def space_icon(name, **options)
    paths = {
      "alien" => '<path d="M12 3C6 3 3 6.5 4 12c.8 4.5 5.7 9 8 9s7.2-4.5 8-9c1-5.5-2-9-8-9Z"/><path d="M7 10c3 0 4 2 4 4-3 0-4-2-4-4Zm10 0c-3 0-4 2-4 4 3 0 4-2 4-4Z"/><path d="M10 17h4"/>',
      "planet" => '<circle cx="12" cy="12" r="7"/><path d="M5.5 8C-3 12 1 18 13 15s16-10 5-9M8 6l2 2m5 6 2 3"/>',
      "power" => '<path d="m13 2-9 12h7l-1 8 10-13h-7l1-7Z"/>',
      "ship" => '<path d="M7 12c0-4 2-7 5-7s5 3 5 7"/><ellipse cx="12" cy="13" rx="10" ry="4"/><path d="m8 20 1-2m7 2-1-2m-3 3v-3M7 13h.01M12 14h.01M17 13h.01"/>',
      "arrow" => '<path d="M4 12h16m-6-6 6 6-6 6"/>',
      "plus" => '<path d="M12 5v14M5 12h14"/>',
      "back" => '<path d="M20 12H4m6-6-6 6 6 6"/>',
      "close" => '<path d="m6 6 12 12M6 18 18 6"/>',
      "check" => '<path d="m5 12 4 4L19 6"/>',
      "edit" => '<path d="m15 4 5 5M4 20l5-1L21 7l-5-5L4 14v6Z"/>',
      "trash" => '<path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7m4-7v7"/>'
    }
    content_tag(:svg, paths.fetch(name, paths["planet"]).html_safe, **{ viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.4, "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true, class: "icon" }.merge(options))
  end

  def record_name(record)
    record.name.presence || "Unnamed #{record.model_name.human.downcase}"
  end

  def file_number(record)
    format("%03d", record.id)
  end
end
