class Avo::ToolsController < Avo::ApplicationController
  def coach_dashboard
    @page_title = "Coach dashboard"
    add_breadcrumb "Coach dashboard"
  end
end
