class Avo::Cards::UsersMetric < Avo::Cards::MetricCard
  self.id = "users_metric"
  self.label = "Users metric"
  # self.description = "Some description"
  # self.cols = 1
  # self.initial_range = 30
  # self.ranges = {
  #   "7 days": 7,
  #   "30 days": 30,
  #   "60 days": 60,
  #   "365 days": 365,
  #   Today: "TODAY",
  #   "Month to date": "MTD",
  #   "Quarter to date": "QTD",
  #   "Year to date": "YTD",
  #   All: "ALL",
  # }
  # self.prefix = ""
  # self.suffix = ""

  def query
    result User.count
  end
end
