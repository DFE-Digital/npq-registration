class NpqSeparation::Admin::CohortsController < NpqSeparation::AdminController
  before_action :ensure_super_admin, except: %i[index show]
  before_action :cohort, only: %i[show edit update destroy]

  def index
    @pagy, @cohorts = pagy(Cohort.all.order(start_year: :desc))
  end

  def show; end

  def new
    @cohort = Cohort.new
    render :form
  end

  def create
    @cohort = Cohort.new(cohort_params)

    if @cohort.save
      Cohorts::CopyDeliveryPartnersJob.perform_later(@cohort.id)
      flash[:success] = "Cohort created"
      redirect_to action: :index
    else
      render :form, status: :unprocessable_entity
    end
  end

  def edit
    render :form
  end

  def update
    if @cohort.update(cohort_params)
      flash[:success] = "Cohort updated"
      redirect_to npq_separation_admin_cohort_path(@cohort)
    else
      render :form, status: :unprocessable_entity
    end
  end

  def destroy
    if params[:confirm].present?
      @cohort.destroy!
      flash[:success] = "Cohort deleted"
      redirect_to action: :index
    else
      render :destroy
    end
  end

  def download_contracts
    send_data Exporters::Contracts.new(cohort:).call, filename: "#{cohort.start_year}_cohort_contracts.csv", type: :csv
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
end
