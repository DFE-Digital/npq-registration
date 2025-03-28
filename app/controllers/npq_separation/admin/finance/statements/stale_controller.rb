class NpqSeparation::Admin::Finance::Statements::StaleController < NpqSeparation::AdminController
  def index
    @statements = Statement.with_delayed_authorisations
  end
end
