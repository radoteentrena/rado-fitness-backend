class FileContentTypeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return unless value.attached?

    allowed = Array(options[:in])
    return if allowed.blank?

    unless allowed.include?(value.blob.content_type)
      record.errors.add(attribute, :invalid_content_type,
        message: "must be one of: #{allowed.join(', ')}")
    end
  end
end
