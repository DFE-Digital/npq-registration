class NpqSeparation::Admin::CohortsController < NpqSeparation::AdminController
  def index
    @pagy, @cohorts = pagy(Cohort.all.order(start_year: :desc))
  end

  def show
    @cohort = Cohort.find(params[:id])
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
    @cohort = Cohort.find(params[:id])

    render :form
  end

  def update
    @cohort = Cohort.find(params[:id])

    if @cohort.update(cohort_params)
      flash[:success] = "Cohort updated"
      redirect_to npq_separation_admin_cohort_path(@cohort)
    else
      render :form, status: :unprocessable_entity
    end
  end

private

  def cohort_params
    params.require(:cohort).permit(:start_year, :registration_start_date, :funding_cap)
  end
end
