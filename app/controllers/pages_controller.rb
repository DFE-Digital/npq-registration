class PagesController < PublicPagesController
  def show
    if params[:page] == "closed_registration_exception" && !Feature.registration_closed?(current_user)
      return redirect_to root_path
    end

    render template: "pages/#{params[:page]}"
  end
end
