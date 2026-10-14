class PagesController < PublicPagesController
  def show
    if params[:page] == "closed_registration_exception"
      unless Feature.registration_closed?(current_user)
        return redirect_to root_path
      end

      unless Rails.configuration.x.teacher_auth.enabled
        return redirect_to registration_closed_path
      end
    end

    respond_to do |format|
      format.html { render template: "pages/#{params[:page]}" }
    end
  rescue ActionView::MissingTemplate
    raise ActionController::RoutingError, "Not Found"
  end
end
