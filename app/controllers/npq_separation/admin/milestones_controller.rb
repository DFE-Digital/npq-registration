class NpqSeparation::Admin::MilestonesController < NpqSeparation::AdminController
  before_action :set_cohort
  before_action :set_schedule
  before_action :ensure_super_admin
  before_action :set_milestone, only: %i[edit update destroy]
  before_action :set_new_statement_date, only: %i[create update]
  before_action :set_statement_date_options, only: %i[new edit]

  def new
    @declaration_types_available = @schedule.allowed_declaration_types - @schedule.milestones.pluck(:declaration_type)
  end

  def create
    ActiveRecord::Base.transaction do
      milestone = @schedule.milestones.create!(params.fetch(:milestone).permit(:declaration_type))
      LeadProvider.find_each do |lead_provider|
        statement = lead_provider
          .statements
          .find_by(month: @new_statement_date.month, year: @new_statement_date.year)
        milestone.milestone_statements.find_or_create_by!(statement: statement)
      end
      flash[:success] = "Milestone created"
    end
    redirect_to npq_separation_admin_cohort_schedule_path(@schedule.cohort, @schedule)
  end

  def edit
    # empty method to appease rubocop
  end

  def update
    @milestone.milestone_statements.destroy_all
    ActiveRecord::Base.transaction do
      LeadProvider.find_each do |lead_provider|
        statement = lead_provider
          .statements
          .find_by(month: @new_statement_date.month, year: @new_statement_date.year)
        @milestone.milestone_statements.find_or_create_by!(statement: statement)
      end
      flash[:success] = "Milestone updated"
    end
    redirect_to npq_separation_admin_cohort_schedule_path(@schedule.cohort, @schedule)
  end

  def destroy
    if params[:confirm].present?
      ActiveRecord::Base.transaction do
        @milestone.milestone_statements.destroy_all
        @milestone.destroy!
        flash[:success] = "Milestone deleted"
      end
      redirect_to npq_separation_admin_cohort_schedule_path(@schedule.cohort, @schedule)
    end
  end

private

  def set_cohort
    @cohort = Cohort.find(params[:cohort_id])
  end

  def set_schedule
    @schedule = @cohort.schedules.find(params[:schedule_id])
  end

  def set_milestone
    @milestone = Milestone.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to npq_separation_admin_cohort_schedule_path(@schedule.cohort, @schedule)
  end

  def set_new_statement_date
    @new_statement_date = Date.parse(params[:milestone][:statement_date])
  end

  def set_statement_date_options
    @statement_date_options =
      Statement
      .where(cohort: @cohort, output_fee: true)
      .order(year: :asc, month: :asc)
      .pluck(:year, :month)
      .uniq
      .map do |year, month|
        OpenStruct.new(
          year_month: Date.new(year, month),
          label: Date.new(year, month).to_fs(:govuk_approx),
        )
      end
  end

  def ensure_super_admin
    unless current_admin.super_admin?
      flash[:error] = "You must be a super admin to change milestones"
      redirect_to npq_separation_admin_cohort_schedule_path(@schedule.cohort, @schedule)
    end
  end
end
