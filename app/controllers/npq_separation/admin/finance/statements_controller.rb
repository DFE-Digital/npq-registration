class NpqSeparation::Admin::Finance::StatementsController < NpqSeparation::AdminController
  def index
    @statements = Statements::Find.new.all
  end

  def show
    @statement = Statements::Find.new.find_by_id(params[:id])
  end
end
