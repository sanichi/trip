module DayHelper
  def day_date(day)
    day.date.strftime("%a %b %-d")
  end

  def day_ready_badge(day)
    if day.draft
      content_tag(:span, t('symbol.cross'), class: "badge bg-warning text-dark")
    else
      content_tag(:span, t('symbol.tick'), class: "badge bg-success")
    end
  end

  def day_previous(day)
    day.trip.days.where("date < ?", day.date).reorder(date: :desc).first
  end

  def day_next(day)
    day.trip.days.where("date > ?", day.date).reorder(date: :asc).first
  end
end
