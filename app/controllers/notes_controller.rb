class NotesController < ApplicationController
  # see https://github.com/CanCanCommunity/cancancan/wiki/Controller-Authorization-Example
  # and https://github.com/CanCanCommunity/cancancan/wiki/Authorizing-controller-actions
  load_and_authorize_resource

  def index
    @notes = Note.search(@notes, params, notes_path, per_page: 10)
  end

  def create
    @note.user_id = current_user.id
    if @note.save
      redirect_to @note
    else
      failure @note
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @note.update(resource_params)
      redirect_to @note
    else
      failure @note
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @note.destroy
    redirect_to notes_path
  end

  private

  def resource_params
    params.require(:note).permit(:draft, :markdown, :title)
  end
end
