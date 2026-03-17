class Api::V1::ProgressPhotosController < Api::V1::BaseController
  def create
    @photo = current_user.progress_photos.build(photo_params)

    if @photo.save
      render json: {
        id: @photo.id,
        date: @photo.date,
        note: @photo.note,
        image_url: url_for(@photo.image)
      }, status: :created
    else
      render json: { errors: @photo.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def photo_params
    params.require(:progress_photo).permit(:image, :date, :note)
  end
end
