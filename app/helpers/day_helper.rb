module DayHelper
  def day_ready_badge(day)
    if day.draft
      content_tag(:span, t('symbol.cross'), class: "badge bg-warning text-dark")
    else
      content_tag(:span, t('symbol.tick'), class: "badge bg-success")
    end
  end
end
