class Api::V1::ProgressPhotosController < Api::V1::BaseController
  def index
    photos = current_user.progress_photos.order(date: :desc).limit(50)
    render json: {
      photos: photos.map do |photo|
        {
          id:        photo.id,
          date:      photo.date,
          note:      photo.note,
          image_url: photo.image.attached? ? rails_blob_url(photo.image, disposition: "inline") : nil
        }
      end
    }
  end

  def create
    @photo = current_user.progress_photos.build(photo_params)

    if @photo.save
      render json: {
        id: @photo.id,
        date: @photo.date,
        note: @photo.note,
        image_url: rails_blob_url(@photo.image, disposition: "inline")
      }, status: :created
    else
      render json: { errors: @photo.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    photo = current_user.progress_photos.find(params[:id])
    photo.destroy
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Photo not found" }, status: :not_found
  end

  private

  def photo_params
    params.require(:progress_photo).permit(:image, :date, :note)
  end
end
