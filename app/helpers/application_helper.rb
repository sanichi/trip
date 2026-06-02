module ApplicationHelper
  def pagination_links(pager)
    links = Array.new
    links.push(link_to t("pagination.frst"), pager.frst_page, id: "pagn_frst") if pager.after_start?
    links.push(link_to t("pagination.next"), pager.next_page, id: "pagn_next") if pager.before_end?
    links.push(link_to t("pagination.prev"), pager.prev_page, id: "pagn_prev") if pager.after_start?
    links.push(link_to t("pagination.last"), pager.last_page, id: "pagn_last") if pager.before_end?
    raw "#{pager.min_and_max} #{t('pagination.of')} #{pager.count} #{links.size > 0 ? '∙' : ''} #{links.join(' ∙ ')}"
  end

  def home_page
    controller_name == "pages" && action_name == "home"
  end

  def col(cols)
    case cols
    when true
      "col"
    when false, nil
      ""
    else
      cols.to_s.gsub(/(\A| )((?:sm|md|lg|xl|xxl)-)?(\d)/){"#{$1}col-#{$2}#{$3}"}
    end
  end

  def link_last_edited
    return unless session[:last_edited]&.match(/\A(\d+),(\d+)\z/)
    trip = Trip.find_by(id: $1.to_i)
    return unless trip && can?(:read, trip)
    day = $2.to_i == 0 ? nil : trip.days.find_by(id: $2.to_i)
    path = day ? trip_day_path(trip, day) : trip_path(trip)
    return if request.fullpath == path
    content_tag(:li, link_to(t("day.last_edited"), path))
  end
end
