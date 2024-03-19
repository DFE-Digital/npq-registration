class NpqSeparation::AdminController < ApplicationController
  layout "admin"
  before_action :require_admin

  include Pagy::Backend

private

  def require_admin
    unless current_admin
      flash[:negative] = { title: "Unauthorized", text: "Sign in with your admininstrator account" }
      redirect_to sign_in_path
    end
  end
end
