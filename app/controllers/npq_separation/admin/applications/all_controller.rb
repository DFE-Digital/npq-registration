class NpqSeparation::Admin::Applications::AllController < NpqSeparation::AdminController
  def index
    @applications = Applications::Find.new.all
  end
end
