class NpqSeparation::Admin::Dashboards::SummaryController < NpqSeparation::AdminController
  def show
    @courses = tally_applications_by :course
    @lead_providers = tally_applications_by :lead_provider
  end

private

  def tally_applications_by(dimension)
    column = "#{dimension.to_s.pluralize}.name"
    Application.where(cohort:).joins(dimension).pluck(column).tally.sort
  end

  def cohort
    @cohort ||= Cohort.current
  end
end
