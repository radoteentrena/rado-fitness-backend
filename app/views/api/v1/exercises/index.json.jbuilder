json.array! @exercises do |exercise|
  json.extract! exercise, :id, :name, :muscle_group, :video_link, :description
end
