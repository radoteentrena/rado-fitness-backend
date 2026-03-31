require "administrate/field/base"

class HumanizedTimestampField < Administrate::Field::Base
  def to_s
    return "—" if data.nil?

    now = Time.current
    diff = (now - data).round

    if diff < 60
      "Just now"
    elsif diff < 3600
      "#{(diff / 60).round}m ago"
    elsif diff < 86400
      time_str = data.strftime("%I:%M %p").downcase
      "Today at #{time_str}"
    elsif diff < 172800
      "Yesterday"
    elsif diff < 604800
      "#{(diff / 86400).round}d ago"
    else
      data.strftime("%b %d, %Y")
    end
  end
end
