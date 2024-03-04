class NpqSeparation::Admin::Finance::Statements::UnpaidController < NpqSeparation::AdminController
  def index
    @statements = Statements::Find.new.unpaid
  end
end
