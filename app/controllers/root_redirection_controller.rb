class RootRedirectionController < ApplicationController
  def redirect
    if Feature.registration_closed?(current_user)
      redirect_to registration_closed_path
    else
      redirect_to registration_wizard_show_path(step: :start)

    end
  end
end
