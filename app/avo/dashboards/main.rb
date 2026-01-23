class Avo::Dashboards::Main < Avo::Dashboards::BaseDashboard
  self.id = "main"
  self.name = "Main"
  # self.description = "Tiny dashboard description"
  # self.grid_cols = 3
  # self.visible = -> do
  #   true
  # end

  def cards
    card Avo::Cards::UsersMetric
    card Avo::Cards::RecentPrograms
    card Avo::Cards::GoogleCalendar
  end
end
