class NpqSeparation::Admin::SchedulesController < NpqSeparation::AdminController
  before_action :ensure_super_admin, except: :show
  before_action :schedule, only: %i[show edit update destroy]

  def show; end

  def new
    @schedule = cohort.schedules.new
    render :form
  end

  def create
    @schedule = cohort.schedules.new(schedule_params)

    if @schedule.save
      flash[:success] = "Schedule created"
      redirect_to npq_separation_admin_cohort_path(cohort)
    else
      render :form, status: :unprocessable_entity
    end
  end

  def edit
    render :form
  end

  def update
    if @schedule.update(schedule_params)
      flash[:success] = "Schedule updated"
      redirect_to npq_separation_admin_cohort_path(cohort)
    else
      render :form, status: :unprocessable_entity
    end
  end

  def destroy
    if params[:confirm].present?
      @schedule.destroy!
      flash[:success] = "Schedule deleted"
      redirect_to npq_separation_admin_cohort_path(@schedule.cohort)
    else
      render :destroy
    end
  end

private

  def schedule_params
    params.require(:schedule).permit(:course_group_id, :name, :identifier, :applies_from, :applies_to, allowed_declaration_types: [])
  end

  def schedule
    @schedule ||= cohort.schedules.find(params[:id])
  end

  def cohort
    @cohort ||= Cohort.find(params[:cohort_id])
  end

  def ensure_super_admin
    unless current_admin.super_admin?
      flash[:error] = "You must be a super admin to change schedules"
      redirect_to npq_separation_admin_cohort_path(cohort)
    end
  end
end
