class PagesController < ApplicationController
  # see https://github.com/CanCanCommunity/cancancan/wiki/Non-RESTful-Controllers
  authorize_resource class: false

  layout "viewer", only: [:home]

  def home
    @trips = Trip.ready.reorder(start_date: :desc)
    return if @trips.empty?

    @trip = select_trip
    @days = @trip.days.where(draft: false).order(:date)
    @day = select_day

    store_last_visited_day
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

    # If trip param, use that trip
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

  def select_day
    # If day param provided and valid
    if params[:day].present?
      day = @days.find_by(id: params[:day])
      return day if day
    end

    # If trip param (switching trips), check session for last day in this trip
    if params[:trip].present? && session[:last_day_per_trip]&.key?(@trip.id.to_s)
      day = @days.find_by(id: session[:last_day_per_trip][@trip.id.to_s])
      return day if day
    end

    # If session has last visited day for this trip
    if session[:last_day_per_trip]&.key?(@trip.id.to_s)
      day = @days.find_by(id: session[:last_day_per_trip][@trip.id.to_s])
      return day if day
    end

    # In-progress trip: latest ready day; otherwise: first ready day
    if Date.current.between?(@trip.start_date, @trip.end_date)
      @days.last
    else
      @days.first
    end
  end

  def store_last_visited_day
    session[:last_day_per_trip] ||= {}
    session[:last_day_per_trip][@trip.id.to_s] = @day.id
  end
end
