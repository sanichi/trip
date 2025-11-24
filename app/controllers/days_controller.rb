class DaysController < ApplicationController
  include TripHelper

  before_action :set_trip
  load_and_authorize_resource :trip
  load_and_authorize_resource :day, through: :trip

  def new
    first_slot = trip_first_available_slot(@trip)
    if first_slot.nil?
      flash[:alert] = "No available date slots left for this trip"
      redirect_to trip_path(@trip)
    else
      @day.date = first_slot
    end
  end

  def create
    if @day.save
      redirect_to trip_day_path(@trip, @day)
    else
      failure @day
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @day.update(resource_params)
      redirect_to trip_day_path(@trip, @day)
    else
      failure @day
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @day.destroy
    redirect_to trip_path(@trip)
  end

  def toggle_draft
    @day.update!(draft: !@day.draft)
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_trip
    @trip = Trip.find(params[:trip_id])
  end

  def resource_params
    params.require(:day).permit(:date, :title, :draft, :notes)
  end
end
