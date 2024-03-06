class NpqSeparation::Admin::Finance::Statements::PaidController < NpqSeparation::AdminController
  def index
    @statements = Statements::Find.new.paid
  end
end
