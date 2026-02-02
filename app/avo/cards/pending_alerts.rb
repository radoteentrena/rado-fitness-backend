class Avo::Cards::PendingAlerts < Avo::Cards::MetricCard
  self.id = "pending_alerts"
  self.label = "Priority Inbox (Pending)"
  self.description = "Urgent alerts requiring your attention."
  # self.cols = 1
  # self.initial_range = 30
  # self.ranges = [7, 30, 60, 365, "TODAY", "MTD", "QTD", "YTD", "ALL"]
  # self.prefix = ""
  # self.suffix = ""

  def query
    result CoachAlert.pending.count
  end
end
