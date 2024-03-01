class NpqSeparation::Admin::Finance::StatementsController < NpqSeparation::AdminController
  def index
    @statements = Statements::Find.new.all
  end
end
