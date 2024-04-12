module Migration::Migrators
  class Statement < Base
    def call
      migrate(ecf_statements, :statement) do |ecf_statement|
        statement = ::Statement.find_or_initialize_by(month: Date::MONTHNAMES.find_index(ecf_statement.name.split[0]), year: ecf_statement.name.split[1])

        statement.update!(
          deadline_date: ecf_statement.deadline_date,
          payment_date: ecf_statement.payment_date,
          output_fee: ecf_statement.output_fee,
          cohort: ::Cohort.find_by(start_year: ecf_cohorts.find_by(id: ecf_statement.cohort_id).start_year),
          lead_provider: ::LeadProvider.find_by(ecf_id: ecf_statement.cpd_lead_provider.npq_lead_provider.id),
          marked_as_paid_at: ecf_statement.marked_as_paid_at,
          reconcile_amount: ecf_statement.reconcile_amount,
          state: if ecf_statement.type == "Finance::Statement::NPQ::Payable"
                   :payable
                 else
                   ecf_statement.type == "Finance::Statement::NPQ::Paid" ? :paid : :open
                 end,
          ecf_id: ecf_statement.id,
        )
      end
    end

  private

    def ecf_statements
      @ecf_statements ||= Migration::Ecf::Finance::Statement.all
    end

    def ecf_cohorts
      @ecf_cohorts ||= Migration::Ecf::Cohort.where(start_year: 2021..)
    end
  end
end
