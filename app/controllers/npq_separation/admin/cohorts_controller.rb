class NpqSeparation::Admin::CohortsController < NpqSeparation::AdminController
  before_action :ensure_super_admin, except: %i[index show]
  before_action :ensure_editable, only: %i[edit update destroy]

  def index
    @pagy, @cohorts = pagy(Cohort.all.order(start_year: :desc))
  end

  def show
    @cohort = cohort
  end

  def new
    @cohort = Cohort.new
    render :form
  end

  def create
    @cohort = Cohort.new(cohort_params)

    if @cohort.save
      flash[:success] = "Cohort created"
      redirect_to action: :index
    else
      render :form, status: :unprocessable_entity
    end
  end

  def edit
    @cohort = cohort
    render :form
  end

  def update
    if cohort.update(cohort_params)
      flash[:success] = "Cohort updated"
      redirect_to npq_separation_admin_cohort_path(cohort)
    else
      @cohort = cohort
      render :form, status: :unprocessable_entity
    end
  end

  def destroy
    if params[:confirm].present?
      cohort.destroy!
      flash[:success] = "Cohort deleted"
      redirect_to action: :index
    else
      @cohort = cohort
      render :destroy
    end
  end

private

  def cohort_params
    params.require(:cohort).permit(:start_year, :registration_start_date, :funding_cap)
  end

  def cohort
    @cohort ||= Cohort.find(params[:id])
  end

  def ensure_super_admin
    unless current_admin.super_admin?
      flash[:error] = "You must be a super admin to change cohorts"
      redirect_to action: :index
    end
  end

  def ensure_editable
    unless cohort.editable?
      flash[:error] = "This cohort is not editable"
      redirect_to npq_separation_admin_cohort_path(cohort)
    end
  end
end
