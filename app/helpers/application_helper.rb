module ApplicationHelper
  ICONS = {
    pulse: "M2 13h5l3-9 4 16 3-9h5",
    today: "M3 10l9-7 9 7v10h-6v-6H9v6H3z",
    workouts: "M3 9v6m3-9v12m12-12v12m3-9v6M6 12h12",
    dashboard: "M3 4v16h18M6 15l5-6 4 3 6-8",
    labs: "M9 3h6m-5 0v6L4 19q-1 2 2 2h12q3 0 2-2L14 9V3M7 15h10",
    profile: "M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0ZM4 21v-1a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6v1",
    water: "M12 2C10 6 5 11 5 15a7 7 0 0 0 14 0c0-4-5-9-7-13z",
    sleep: "M20 15a8 8 0 0 1-11-11 9 9 0 1 0 11 11z",
    clock: "M12 4a8 8 0 1 0 .1 0M12 8v5l3 2",
    exit: "M10 4H4v16h6m4-13 5 5-5 5m-5-5h10"
  }.freeze

  def icon(name)
    tag.svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.7,
      "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true, class: "icon") do
      tag.path(d: ICONS.fetch(name))
    end
  end

  def clock_time(seconds)
    hours, remainder = seconds.to_i.divmod(3600)
    minutes, seconds = remainder.divmod(60)
    hours.positive? ? format("%d:%02d:%02d", hours, minutes, seconds) : format("%d:%02d", minutes, seconds)
  end

  def quantity(value, delimiter: ".")
    number_with_delimiter(value.to_d.to_s("F").sub(/\.0\z/, ""), separator: ",", delimiter: delimiter)
  end

  def workout_name(workout)
    workout.running? ? "Corrida" : "Musculação"
  end

  def workout_status(workout)
    return "Finalizado" if workout.finished_at?

    workout.paused? ? "Pausado" : "Em andamento"
  end

  def chart_points(history)
    first, last = history.keys.minmax
    low, high = history.values.minmax
    history.map do |day, kg|
      x = first == last ? 160 : 10 + 300 * (day - first).to_f / (last - first)
      y = low == high ? 45 : 80 - 70 * (kg - low) / (high - low)
      [ x.round(1), y.to_f.round(1) ]
    end
  end
end
