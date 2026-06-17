class RegistrationClosedController < PublicPagesController
  def show
    @one_login = params[:one_login] == "true"
    redirect_to root_path unless Feature.registration_closed?(current_user)
  end

  def change; end
end
