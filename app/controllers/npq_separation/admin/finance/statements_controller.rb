class NpqSeparation::Admin::Finance::StatementsController < NpqSeparation::AdminController
  def index
    @pagy, @statements = pagy(Statements::Find.new.all)
  end

  def show
    @statement = Statements::Find.new.find_by_id(params[:id])
  end
end
