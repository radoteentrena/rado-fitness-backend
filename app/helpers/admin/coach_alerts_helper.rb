module Admin
  module CoachAlertsHelper
    ALERT_STATUS_CLASSES = {
      "pending"   => "bg-primary/10 text-primary border border-primary/20",
      "resolved"  => "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300 border border-green-200 dark:border-green-700",
      "dismissed" => "bg-graphite/20 text-graphite dark:bg-graphite/40 dark:text-muted border border-graphite/30"
    }.freeze

    def alert_status_classes(status)
      ALERT_STATUS_CLASSES[status.to_s] || ""
    end
  end
end
