class NpqSeparation::Admin::ApplicationsController < NpqSeparation::AdminController
  def index
    @applications = Applications::Find.new.all
  end
end
