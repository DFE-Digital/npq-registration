class NpqSeparation::Admin::Dashboards::SummaryController < NpqSeparation::AdminController
  def show
    @applications_this_week = Application.where(created_at: 1.week.ago..).count
    @applications_this_month = Application.where(created_at: 1.month.ago..).count
    @applications_this_year = Application.where(created_at: 1.year.ago..).count
  end
end
