class ImagesController < ApplicationController
  load_and_authorize_resource

  def index
    @images = Image.search(@images, params, images_path, per_page: 10)
  end

  def create
    @image.user_id = current_user.id
    if @image.save
      redirect_to @image
    else
      failure @image
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @image.update(resource_params)
      redirect_to @image
    else
      failure @image
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @image.destroy
    redirect_to images_path
  end

  private

  def resource_params
    params.require(:image).permit(:caption, :file)
  end
end
