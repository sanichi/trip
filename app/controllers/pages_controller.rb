class PagesController < ApplicationController
  # see https://github.com/CanCanCommunity/cancancan/wiki/Non-RESTful-Controllers
  authorize_resource class: false

  layout "viewer", only: [:home]

  def home
    @trips = Trip.ready.reorder(start_date: :desc)
    return if @trips.empty?

    @trip = select_trip
    @days = @trip.days.where(draft: false).order(:date)
    @show_intro = select_intro?
    @day = select_day unless @show_intro

    store_last_visited
  end

  def env
    @sys_info = Sni::SysInfo.call
  end

  private

  def select_trip
    # If day param, get trip from day
    if params[:day].present?
      day = Day.find_by(id: params[:day], draft: false)
      return day.trip if day&.trip&.ready?
    end

    # If trip param or intro param, use that trip
    if params[:trip].present?
      trip = @trips.find_by(id: params[:trip])
      return trip if trip
    end

    # If session has last visited trip/day, use that trip
    if session[:last_day_per_trip].present?
      last_trip_id = session[:last_day_per_trip].keys.last
      trip = @trips.find_by(id: last_trip_id)
      return trip if trip
    end

    # Find in-progress trip (today is within trip dates)
    in_progress = @trips.find { |t| Date.current.between?(t.start_date, t.end_date) }
    return in_progress if in_progress

    # Default to latest trip
    @trips.first
  end

  def select_intro?
    # Explicit day param means we're not on intro
    return false if params[:day].present? && @days.exists?(id: params[:day])

    # Explicit intro param
    return true if params[:intro].present?

    # No ready days means intro is the only option
    return true if @days.empty?

    # Session indicates intro was last viewed for this trip
    if session[:last_day_per_trip]&.key?(@trip.id.to_s)
      return session[:last_day_per_trip][@trip.id.to_s] == "intro"
    end

    false
  end

  def select_day
    # If day param provided and valid
    if params[:day].present?
      day = @days.find_by(id: params[:day])
      return day if day
    end

    # If trip param (switching trips), check session for last day in this trip
    if params[:trip].present? && session[:last_day_per_trip]&.key?(@trip.id.to_s)
      last_value = session[:last_day_per_trip][@trip.id.to_s]
      # Skip if session says intro
      unless last_value == "intro"
        day = @days.find_by(id: last_value)
        return day if day
      end
    end

    # If session has last visited day for this trip (and it's not intro)
    if session[:last_day_per_trip]&.key?(@trip.id.to_s)
      last_value = session[:last_day_per_trip][@trip.id.to_s]
      unless last_value == "intro"
        day = @days.find_by(id: last_value)
        return day if day
      end
    end

    # In-progress trip: latest ready day; otherwise: first ready day
    if Date.current.between?(@trip.start_date, @trip.end_date)
      @days.last
    else
      @days.first
    end
  end

  def store_last_visited
    session[:last_day_per_trip] ||= {}
    if @show_intro
      session[:last_day_per_trip][@trip.id.to_s] = "intro"
    else
      session[:last_day_per_trip][@trip.id.to_s] = @day&.id
    end
  end
end
