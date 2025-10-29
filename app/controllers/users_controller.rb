class UsersController < ApplicationController
  load_and_authorize_resource

  def create
    if @user.save
      redirect_to @user
    else
      failure @user
      render :new
    end
  end

  def update
    if @user.update(resource_params)
      redirect_to @user
    else
      failure @user
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path
  end

  private

  def resource_params
    params.require(:user).permit(:email, :name, :otp_required, :password)
  end
end
