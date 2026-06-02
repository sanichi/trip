module DayHelper
  def day_label(day, long: true)
    if long
      t('day.label', sequence: day.sequence)
    else
      t('day.short.label', sequence: day.sequence)
    end
  end

  def day_date(day, long: false)
    if long
      day.date.strftime("%A %B %-d")
    else
      day.date.strftime("%a %b %-d")
    end
  end

  def day_ready_badge(day)
    badge = if day.draft
      content_tag(:span, t('symbol.cross'), class: "badge bg-warning text-dark align-text-top")
    else
      content_tag(:span, t('symbol.tick'), class: "badge bg-success align-text-top")
    end
    content_tag(:small, badge)
  end

  def day_previous(day)
    day.trip.days.where("date < ?", day.date).reorder(date: :desc).first ||
      day.trip.days.where("date > ?", day.date).reorder(date: :desc).first
  end

  def day_next(day)
    day.trip.days.where("date > ?", day.date).reorder(date: :asc).first ||
      day.trip.days.where("date < ?", day.date).reorder(date: :asc).first
  end

  def day_last_edited
    return unless session[:last_edited]&.match(/\A(\d+),(\d+)\z/)
    trip = Trip.find_by(id: $1.to_i)
    return unless trip && can?(:read, trip)
    day = $2.to_i == 0 ? nil : trip.days.find_by(id: $2.to_i)
    path = day ? trip_day_path(trip, day) : trip_path(trip)
    return if request.fullpath == path
    content_tag(:li, link_to(t("day.last_edited"), path))
  end
end
