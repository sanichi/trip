module TripHelper
  def trip_duration(trip)
    year_in_title = trip.title.match?(/\b#{trip.start_date.year}\b/)
    same_month = trip.start_date.month == trip.end_date.month && trip.start_date.year == trip.end_date.year

    if same_month
      month_name = trip.start_date.strftime("%B")
      start_day = trip.start_date.day
      end_day = trip.end_date.day
      duration = "#{month_name} #{start_day}-#{end_day}"
    else
      start_abbr = trip.start_date.strftime("%b")
      end_abbr = trip.end_date.strftime("%b")
      duration = "#{start_abbr} #{trip.start_date.day} - #{end_abbr} #{trip.end_date.day}"
    end

    year_in_title ? duration : "#{duration}, #{trip.start_date.year}"
  end

  def trip_first_available_slot(trip)
    used_dates = trip.days.pluck(:date).to_set
    (trip.start_date..trip.end_date).find { |date| !used_dates.include?(date) }
  end

  def trip_ready_badge(trip)
    badge = if trip.draft
      content_tag(:span, t('symbol.cross'), class: "badge bg-warning text-dark align-text-top")
    else
      content_tag(:span, t('symbol.tick'), class: "badge bg-success align-text-top")
    end
    content_tag(:small, badge)
  end
end
