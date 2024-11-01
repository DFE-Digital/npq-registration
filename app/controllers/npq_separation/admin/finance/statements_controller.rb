class NpqSeparation::Admin::Finance::StatementsController < NpqSeparation::AdminController
  def index
    scope = Statement.includes(:lead_provider, :cohort)
                     .where(statement_params)
                     .order(payment_date: :asc)

    if scope.one?
      redirect_to action: :show, id: scope.first.id
    else
      scope = scope.unscope(where: %i[year month]) if scope.none?
      @pagy, @statements = pagy(scope)
    end
  end

  def show
    scope = Statement.includes(contracts: [
                                :contract_template,
                                { course: :course_group }
                              ])

    @statement = scope.find(params[:id])
    @npq_special_contracts = []
  end

  private

  def statement_params
    params.permit(:lead_provider_id, :cohort_id, :period)
          .tap { extract_period _1 }
          .select { _2.present? }
  end

  def extract_period(params)
    return unless period = params.delete(:period)

    params[:year], params[:month] = period.split('-')
  end
end
