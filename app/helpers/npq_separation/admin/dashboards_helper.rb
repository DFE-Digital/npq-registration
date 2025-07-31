module NpqSeparation::Admin::DashboardsHelper
  def render_dashboard_partial(name)
    case name
    when "providers-dashboard"
      render "providers_dashboard"
    when "courses-dashboard"
      render "courses_dashboard"
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end
end
