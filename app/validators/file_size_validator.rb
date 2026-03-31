class FileSizeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    max_size = options[:less_than]
    return if max_size.blank?

    if value.attached? && value.blob.byte_size > max_size
      record.errors.add(attribute, :file_size_exceeded,
        message: "file size must be less than #{number_to_human_size(max_size)}")
    end
  end

  private

  def number_to_human_size(size)
    units = %w[B KB MB GB]
    size_f = size.to_f
    index = 0
    while size_f >= 1024 && index < units.length - 1
      size_f /= 1024
      index += 1
    end
    "#{size_f.round(2)} #{units[index]}"
  end
end
