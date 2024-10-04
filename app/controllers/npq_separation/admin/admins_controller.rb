class NpqSeparation::Admin::AdminsController < NpqSeparation::AdminController
  before_action :require_super_admin

  def index
    @admins = Admin.all
  end

  def new
    @admin = Admin.new
  end

  def create
    @admin = Admin.new(admin_params)

    if @admin.save
      flash[:success] = t(".success", email: @admin.email)
      redirect_to action: :index
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @admin = Admin.find(params[:id])

    if !@admin.super_admin? && @admin.update(super_admin: true)
      flash[:success] = t(".success", email: @admin.email)
    else
      flash[:error] = t(".failure", email: @admin.email)
    end

    redirect_to action: :index
  end

  def destroy
    @admin = Admin.find(params[:id])

    if @admin.super_admin?
      flash[:error] = t(".forbidden")
    elsif @admin.destroy
      flash[:success] = t(".success", email: @admin.email)
    else
      flash[:error] = t(".failure", email: @admin.email)
    end

    redirect_to action: :index
  end

private

  def require_super_admin
    unless current_admin.super_admin?
      flash[:negative] = { title: "Unauthorized", text: "Sign in with your admininstrator account" }
      redirect_to sign_in_path
    end
  end

  def admin_params
    params.require(:admin).permit(:email, :full_name)
  end
end
