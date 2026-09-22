# frozen_string_literal: true

module Cohorts
  class ExtendStatements
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :cohort
    attribute :extension_date, :date

    validates :cohort, presence: true
    validates :extension_date, presence: true

    validate :existing_statements
    validate :future_date
    validate :date_extends_existing_end

    def ending_statements
      @ending_statements ||= cohort
        .statements
        .select("DISTINCT ON (lead_providers.name, lead_provider_id) statements.*")
        .includes(:lead_provider)
        .order("lead_providers.name": :asc, lead_provider_id: :asc, year: :desc, month: :desc)
    end

    def last_statement
      @last_statement ||= cohort
        .statements
        .order(year: :desc, month: :desc, created_at: :desc, id: :desc)
        .first
    end

    def schedule_change
      return false if invalid?

      ExtendStatementsJob.perform_later(cohort_id: cohort.id, extension_date:)

      true
    end

    def extend_statements!
      Statement.transaction do
        Statement.with_advisory_lock!("lock-cohort-#{cohort.identifier}") do
          validate!

          ending_statements.includes(:contracts).each do |existing_statement| # rubocop:disable Rails/FindEach - find_each doesn't work inside advisory lock
            existing_date = Date.new(existing_statement.year, existing_statement.month, 2)
            statement_months = (existing_date..extension_date).select { |d| d.day == 1 }

            statement_months.each do |month|
              new_statement =
                clone_statement!(existing_statement, month, month == statement_months.last)

              last_output_statement_for_provider(existing_statement.lead_provider)
                .contracts
                .each { |existing_contract| clone_contract!(existing_contract, new_statement) }
            end
          end

          true
        end
      end
    end

  private

    def future_date
      return if errors.any?
      return if extension_date.future?

      errors.add :extension_date, :in_past
    end

    def date_extends_existing_end
      return if errors.any?
      return if extension_date > date_of_last_statement

      errors.add :extension_date, :before_last_statement
    end

    def date_of_last_statement
      Date.new(*last_statement.values_at(:year, :month))
    end

    def existing_statements
      return if errors.any?
      return if last_statement

      errors.add :extension_date, :no_existing_statements
    end

    def clone_statement!(existing, target_month, output_fee)
      Statement.create!(
        lead_provider: existing.lead_provider,
        cohort_id: existing.cohort_id,
        month: target_month.month,
        year: target_month.year,
        deadline_date: (target_month - 1.month + 24.days),
        payment_date: (target_month + 24.days),
        output_fee:,
        state: (target_month - 1.month + 24.days).future? ? "open" : "payable",
      )
    end

    def clone_contract!(existing, new_statement)
      Contract.create!(
        course_id: existing.course_id,
        contract_template_id: existing.contract_template_id,
        statement: new_statement,
      )
    end

    def last_output_statement_for_provider(provider)
      last_output_statements_by_provider[provider]
    end

    def last_output_statements_by_provider
      @last_output_statements_by_provider ||= ending_statements
        .with_output_fee
        .preload(:contracts) # Cannot use includes() with DISTINCT ON
        .index_by(&:lead_provider)
    end
  end
end
