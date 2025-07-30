module NpqSeparation::Admin::DashboardsHelper
  def render_dashboard_partial(name)
    case name
    when "providers-dashboard"
      render "providers_dashboard"
    when "courses-dashboard"
      render "courses_dashboard"
    else
      content_tag(:p, "Dashboard not found", class: "govuk-body")
    end
  end
end
