class RegistrationClosedController < PublicPagesController
  def show
    redirect_to root_path unless Feature.registration_closed?(current_user)
  end

  def change; end
end
