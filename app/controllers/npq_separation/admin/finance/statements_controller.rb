class NpqSeparation::Admin::Finance::StatementsController < NpqSeparation::AdminController
  def index
    @pagy, @statements = pagy(Statements::Query.new.statements)
  end

  def show
    @statement = Statements::Query.new.statement(id: params[:id])
  end
end
