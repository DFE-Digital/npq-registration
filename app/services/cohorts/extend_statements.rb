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
        .index_by(&:lead_provider)
    end

    def last_statement
      @last_statement ||= cohort
        .statements
        .order(year: :desc, month: :desc, created_at: :desc, id: :desc)
        .first
    end

    def schedule_change
      valid?
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
