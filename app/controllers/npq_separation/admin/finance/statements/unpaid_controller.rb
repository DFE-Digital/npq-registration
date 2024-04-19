class NpqSeparation::Admin::Finance::Statements::UnpaidController < NpqSeparation::AdminController
  def index
    @statements = Statements::Query.new(state: "open,payable").statements
  end
end
