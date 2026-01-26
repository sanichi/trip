module ViewerHelper
  WINDOW_SIZE = 5

  # Returns a sliding window of items (intro + days) centered on the current selection
  # items: array that may start with :intro followed by Day objects
  # current: either :intro or a Day object
  def item_window(items, current)
    return items if items.size <= WINDOW_SIZE

    current_index = items.index(current) || 0
    half = WINDOW_SIZE / 2

    # Calculate window bounds
    start_index = current_index - half
    end_index = current_index + half

    # Adjust if window goes past boundaries
    if start_index < 0
      start_index = 0
      end_index = WINDOW_SIZE - 1
    elsif end_index >= items.size
      end_index = items.size - 1
      start_index = items.size - WINDOW_SIZE
    end

    items[start_index..end_index]
  end

  # Build the list of navigator items (intro + days)
  def navigator_items(days, include_intro)
    include_intro ? [:intro] + days.to_a : days.to_a
  end

  # Current item is either :intro or the current day
  def current_item(day, show_intro)
    show_intro ? :intro : day
  end

  # Show navigator when there's more than one item to navigate
  # (either multiple days, or intro + at least one day)
  def show_day_navigator?(days, include_intro)
    total = days.size + (include_intro ? 1 : 0)
    total > 1
  end

  # Show first/last arrows only when items exceed window size
  def show_nav_arrows?(days, include_intro)
    total = days.size + (include_intro ? 1 : 0)
    total > WINDOW_SIZE
  end

  # Position checks
  def at_first_position?(items, current)
    items.first == current
  end

  def at_last_position?(items, current)
    items.last == current
  end

  # Navigation paths
  def first_position_path(items, trip)
    first = items.first
    first == :intro ? root_path(intro: true, trip: trip.id) : root_path(day: first.id)
  end

  def last_position_path(items)
    last = items.last
    last == :intro ? root_path(intro: true) : root_path(day: last.id)
  end

  def previous_position_path(items, current, trip)
    idx = items.index(current)
    return nil if idx.nil? || idx == 0
    prev_item = items[idx - 1]
    prev_item == :intro ? root_path(intro: true, trip: trip.id) : root_path(day: prev_item.id)
  end

  def next_position_path(items, current)
    idx = items.index(current)
    return nil if idx.nil? || idx == items.size - 1
    next_item = items[idx + 1]
    next_item == :intro ? root_path(intro: true) : root_path(day: next_item.id)
  end

  # Legacy methods for backward compatibility (used by existing day-only code)
  def day_window(days, current_day)
    return days if days.size <= WINDOW_SIZE

    current_index = days.index(current_day)
    half = WINDOW_SIZE / 2

    # Calculate window bounds
    start_index = current_index - half
    end_index = current_index + half

    # Adjust if window goes past boundaries
    if start_index < 0
      start_index = 0
      end_index = WINDOW_SIZE - 1
    elsif end_index >= days.size
      end_index = days.size - 1
      start_index = days.size - WINDOW_SIZE
    end

    days[start_index..end_index]
  end

  def first_day(days)
    days.first
  end

  def last_day(days)
    days.last
  end

  def previous_day(days, current_day)
    current_index = days.index(current_day)
    return nil if current_index.nil? || current_index == 0
    days[current_index - 1]
  end

  def next_day(days, current_day)
    current_index = days.index(current_day)
    return nil if current_index.nil? || current_index == days.size - 1
    days[current_index + 1]
  end

  def at_first_day?(days, current_day)
    days.first == current_day
  end

  def at_last_day?(days, current_day)
    days.last == current_day
  end

  def admin_return_path
    session[:last_admin_page] || trips_path
  end
end
