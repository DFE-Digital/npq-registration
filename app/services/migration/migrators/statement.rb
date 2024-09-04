module Migration::Migrators
  class Statement < Base
    class << self
      def record_count
        ecf_statements.count
      end

      def model
        :statement
      end

      def ecf_statements
        Migration::Ecf::Finance::Statement
          .includes(
            :cohort,
            cpd_lead_provider: :npq_lead_provider,
          )
      end

      def dependencies
        %i[cohort lead_provider]
      end
    end

    def call
      migrate(self.class.ecf_statements) do |ecf_statement|
        statement = ::Statement.find_or_initialize_by(ecf_id: ecf_statement.id)

        statement.update!(
          month: Date::MONTHNAMES.find_index(ecf_statement.name.split[0]),
          year: ecf_statement.name.split[1],
          deadline_date: ecf_statement.deadline_date,
          payment_date: ecf_statement.payment_date,
          output_fee: ecf_statement.output_fee,
          cohort: find_cohort!(start_year: ecf_statement.cohort.start_year),
          lead_provider: find_lead_provider!(ecf_id: ecf_statement.cpd_lead_provider.npq_lead_provider.id),
          marked_as_paid_at: ecf_statement.marked_as_paid_at,
          reconcile_amount: ecf_statement.reconcile_amount,
          state: npq_state(ecf_statement),
        )
      end
    end

  private

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
  end
end
