class TripsController < ApplicationController
  load_and_authorize_resource

  def index
    @trips = @trips.includes(:user)
  end

  def create
    @trip.user_id = current_user.id
    if @trip.save
      redirect_to @trip
    else
      failure @trip
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @trip.update(resource_params)
      redirect_to @trip
    else
      failure @trip
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @trip.destroy
    redirect_to trips_path
  end

  private

  def resource_params
    params.require(:trip).permit(:title, :start_date, :end_date)
  end
end
