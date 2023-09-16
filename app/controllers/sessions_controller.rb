class SessionsController < ApplicationController
  def destroy
    sign_out_all_scopes
    reset_session
    session.clear
    # redirect_to root_path

    root_path = "http://localhost:3000/"
    redirect_to "https://preprod.teaching-identity.education.gov.uk/connect/signout?client_id=register-for-npq=&post_logout_redirect_uri=#{CGI.escape(root_path)}"
  end
end
