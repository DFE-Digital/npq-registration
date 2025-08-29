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
    show_authorising_statement_message(@statement)

    contracts = @statement.contracts.joins(:contract_template, :course).order(identifier: :asc)
    @contracts = contracts.where(contract_template: { special_course: false })
    @special_contracts = contracts.where(contract_template: { special_course: true })
  end

private

  def statement_params
    params.permit(:lead_provider_id, :cohort_id, :payment_status, :statement, :output_fee)
          .tap { extract_period _1 }
          .tap { extract_state _1 }
          .compact_blank
  end

  def extract_period(params)
    return unless (period = params.delete(:statement))

    params[:year], params[:month] = period.split("-")
  end

  def extract_state(params)
    return unless (payment_status = params.delete(:payment_status))

    params[:state] = {
      "unpaid" => %w[open payable],
      "paid" => %w[paid],
    }.fetch(payment_status, [])
  end

  def show_authorising_statement_message(statement)
    return unless statement.authorising_for_payment?

    flash.now[:success_title] =
      t("npq_separation.admin.finance.statements.payment_authorisations.banner.title")

    flash.now[:success] =
      t("npq_separation.admin.finance.statements.payment_authorisations.banner.content",
        statement_marked_as_paid_at: statement.marked_as_paid_at.strftime("%-I:%M%P on %-e %b %Y"))
  end
end
