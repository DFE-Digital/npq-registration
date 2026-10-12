class PagesController < PublicPagesController
  PAGES = %w[
    accessibility
    choose_an_npq_and_provider
    closed_registration_exception
    cookies
  ].freeze

  def show
    raise ActionController::RoutingError, "Not Found" unless PAGES.include?(params[:page])

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
  end
end
