class NpqSeparation::Admin::Finance::StatementsController < NpqSeparation::AdminController
  def index
    scope = Statement.includes(:lead_provider, :cohort)
                     .where(statement_params)
                     .order(payment_date: :asc)

    redirect_to action: :show, id: scope.first.id and return if scope.one?

    if scope.none?
      flash.now[:error] = "No statements matched all the filters, showing all statement periods instead"
      scope = scope.unscope(where: %i[year month])
    end

    @pagy, @statements = pagy(scope)
  end

  def show
    scope = Statement.includes(contracts: [
      :contract_template,
      { course: :course_group },
    ])

    @statement = scope.find(params[:id])
    @calculator = Statements::SummaryCalculator.new(statement: @statement)

    contracts = @statement.contracts.joins(:contract_template, :course).order(identifier: :asc)
    @contracts = contracts.where(contract_template: { special_course: false })
    @special_contracts = contracts.where(contract_template: { special_course: true })
  end

private

  def statement_params
    params.permit(:lead_provider_id, :cohort_id, :statement)
          .tap { extract_period _1 }
          .select { _2.present? }
  end

  def extract_period(params)
    return unless (period = params.delete(:statement))

    params[:year], params[:month] = period.split("-")
  end
end
