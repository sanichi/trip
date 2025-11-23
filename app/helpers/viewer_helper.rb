module ViewerHelper
  WINDOW_SIZE = 5

  # Returns a sliding window of days centered on the current day
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

  def show_nav_arrows?(days)
    days.size > WINDOW_SIZE
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
