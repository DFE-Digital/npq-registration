class NpqSeparation::Admin::MilestonesController < NpqSeparation::AdminController
  before_action :set_cohort
  before_action :set_schedule
  before_action :ensure_super_admin
  before_action :set_milestone, only: %i[edit update destroy]
  before_action :set_statement_date_options, only: %i[new create edit update]
  before_action :set_declaration_types_available, only: %i[new create]

  def new
    @service = Milestones::Create.new(schedule_id: @schedule.id)
  end

  def create
    @service = Milestones::Create.new(
      schedule_id: @schedule.id,
      declaration_type: params.fetch(:milestones_create, {})[:declaration_type],
      statement_date: params.fetch(:milestones_create, {})[:statement_date],
    )
    if @service.valid?
      @service.create!
      flash[:success] = "Milestone created"
      redirect_to npq_separation_admin_cohort_schedule_path(@schedule.cohort, @schedule)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @service = Milestones::Update.new(
      milestone_id: params[:id],
    )
  end

  def update
    @service = Milestones::Update.new(
      milestone_id: params[:id],
      statement_date: params.fetch(:milestones_update, {})[:statement_date],
    )
    if @service.valid?
      @service.update!
      flash[:success] = "Milestone updated"
      redirect_to npq_separation_admin_cohort_schedule_path(@schedule.cohort, @schedule)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if params[:confirm].present?
      Milestones::Destroy.new(milestone_id: params[:id]).destroy!
      flash[:success] = "Milestone deleted"
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

  def set_declaration_types_available
    @declaration_types_available = @schedule.allowed_declaration_types - @schedule.milestones.pluck(:declaration_type)
  end

  def ensure_super_admin
    unless current_admin.super_admin?
      flash[:error] = "You must be a super admin to change milestones"
      redirect_to npq_separation_admin_cohort_schedule_path(@schedule.cohort, @schedule)
    end
  end
end
