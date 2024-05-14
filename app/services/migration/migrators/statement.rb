module Migration::Migrators
  class Statement < Base
    def call
      migrate(ecf_statements, :statement) do |ecf_statement|
        statement = ::Statement.find_or_initialize_by(ecf_id: ecf_statement.id)

        statement.update!(
          month: Date::MONTHNAMES.find_index(ecf_statement.name.split[0]),
          year: ecf_statement.name.split[1],

          deadline_date: ecf_statement.deadline_date,
          payment_date: ecf_statement.payment_date,
          output_fee: ecf_statement.output_fee,
          cohort: cohort(ecf_statement),
          lead_provider: lead_provider(ecf_statement),
          marked_as_paid_at: ecf_statement.marked_as_paid_at,
          reconcile_amount: ecf_statement.reconcile_amount,
          state: npq_state(ecf_statement),
          ecf_id: ecf_statement.id,
        )
      end
    end

  private

    def ecf_statements
      @ecf_statements ||= Migration::Ecf::Finance::Statement.all
    end

    def npq_state(ecf_statement)
      case ecf_statement.type
      when "Finance::Statement::NPQ::Payable"
        :payable
      when "Finance::Statement::NPQ::Paid"
        :paid
      else
        :open
      end
    end

    def lead_provider(ecf_statement)
      ::LeadProvider.find_by(ecf_id: ecf_statement.cpd_lead_provider.npq_lead_provider.id)
    end

    def cohort(ecf_statement)
      ecf_cohort = Migration::Ecf::Cohort.find(ecf_statement.cohort_id)
      ::Cohort.find_by(start_year: ecf_cohort.start_year)
    end
  end
end
