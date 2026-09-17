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

          last_output_statements = ending_statements
            .with_output_fee
            .preload(:contracts) # Cannot use includes() with DISTINCT ON
            .index_by(&:lead_provider)

          ending_statements.includes(:contracts).each do |existing| # rubocop:disable Rails/FindEach - find_each doesn't work inside advisory lock
            existing_date = Date.new(existing.year, existing.month, 2)
            statement_months = (existing_date..extension_date).select { |d| d.day == 1 }

            statement_months.each do |month|
              statement = Statement.create!(
                lead_provider: existing.lead_provider,
                cohort_id: existing.cohort_id,
                month: month.month,
                year: month.year,
                deadline_date: (month - 1.month + 24.days),
                payment_date: (month + 24.days),
                output_fee: month == statement_months.last,
                state: (month - 1.month + 24.days).future? ? "open" : "payable",
              )

              last_output_statements[existing.lead_provider].contracts.each do |contract|
                Contract.create!(
                  course_id: contract.course_id,
                  contract_template_id: contract.contract_template_id,
                  statement:,
                )
              end
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
  end
end
