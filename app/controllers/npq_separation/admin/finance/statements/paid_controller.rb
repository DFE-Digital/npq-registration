class NpqSeparation::Admin::Finance::Statements::PaidController < NpqSeparation::AdminController
  def index
    @statements = Statements::Query.new(state: "paid").statements
  end
end
