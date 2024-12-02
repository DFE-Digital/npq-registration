module OneOff
  class MigrateDeclarationsBetweenStatements
    class StatementMismatchError < RuntimeError; end
    class PaidStatementMigrationError < RuntimeError; end

    include StatementHelper

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :from_month
    attribute :from_year
    attribute :from_statement_updates
    attribute :to_statement_updates
    attribute :to_month
    attribute :to_year
    attribute :cohort
    attribute :restrict_to_lead_providers
    attribute :restrict_to_declaration_types
    attribute :restrict_to_declaration_states
    attribute :restrict_to_course_identifiers

    attribute :override_date_checks, default: false

    validates :from_month, presence: true
    validates :from_year, presence: true
    validates :to_month, presence: true
    validates :to_year, presence: true
    validates :cohort, presence: true

    validate :from_statements_are_not_paid
    validate :statements_are_future_dated, unless: :override_date_checks
    validate :statements_align
    validate :statements_not_empty

    def migrate(dry_run: true)
      Statement.transaction do
        return false unless valid?

        record_summary_info(dry_run)

        migrate_declarations_between_statements!
        update_from_statement_attributes!
        update_to_statement_attributes!

        raise ActiveRecord::Rollback if dry_run
      end

      true
    end

  private

    def from_statements_are_not_paid
      if from_statements_by_provider.values.any?(&:paid?)
        errors.add :base, "Cannot migrate from a paid statement"
      end
    end

    def statements_are_future_dated
      statements = to_statements_by_provider.values

      if statements.any? { |statement| statement.deadline_date.past? }
        errors.add :base, "To statements are not future dated"
      end
    end

    def statements_align
      if from_statements_by_provider.keys.sort != to_statements_by_provider.keys.sort
        errors.add :base, "There is a mismatch between to/from statements"
      end
    end

    def statements_not_empty
      if from_statements_by_provider.empty? && to_statements_by_provider.empty?
        errors.add :base, "No statements were found"
      end
    end

    def update_from_statement_attributes!
      return if from_statement_updates.blank?

      from_statements_by_provider.each_value do |statement|
        statement.update!(from_statement_updates)
        record_info("Statement #{statement.year}-#{statement.month} for #{statement.lead_provider.name} updated with #{from_statement_updates}")
      end
    end

    def update_to_statement_attributes!
      return if to_statement_updates.blank?

      to_statements_by_provider.each_value do |statement|
        statement.update!(to_statement_updates)
        record_info("Statement #{statement.year}-#{statement.month} for #{statement.lead_provider.name} updated with #{to_statement_updates}")
      end
    end

    def each_statements_by_provider
      from_statements_by_provider.each do |provider, from_statement|
        to_statement = to_statements_by_provider[provider]
        yield(provider, from_statement, to_statement)
      end
    end

    def from_statements_by_provider
      @from_statements_by_provider ||= statements_by_provider(from_year, from_month)
    end

    def to_statements_by_provider
      @to_statements_by_provider ||= statements_by_provider(to_year, to_month)
    end

    def provider_count
      from_statements_by_provider.count
    end

    def statements_by_provider(year, month)
      lead_provider = restrict_to_lead_providers || LeadProvider.all

      Statement
        .includes(:cohort, :declarations, :lead_provider)
        .where(cohort:, year:, month:, lead_provider:)
        .group_by(&:lead_provider)
        .transform_values(&:first)
    end

    def filter_statement_items(statement_items)
      scope = statement_items.includes(:declaration)
      scope = scope.where(declaration: { declaration_type: restrict_to_declaration_types }) if restrict_to_declaration_types
      scope = scope.where(declaration: { state: restrict_to_declaration_states }) if restrict_to_declaration_states

      if restrict_to_course_identifiers
        scope = scope.includes(declaration: { application: :course })
                     .where(course: { identifier: restrict_to_course_identifiers })
      end

      scope
    end

    def migrate_declarations_between_statements!
      each_statements_by_provider do |provider, from_statement, to_statement|
        migrate_statement_items!(provider, from_statement, to_statement)
      end
    end

    def migrate_statement_items!(provider, from_statement, to_statement)
      statement_items = filter_statement_items(from_statement.statement_items)

      record_info("Migrating #{statement_items.size} declarations for #{provider.name}")
      statement_items.update!(statement_id: to_statement.id)

      make_eligible_declaration_payable_for_to_statement(to_statement, statement_items)
      make_payable_declaration_eligible_for_to_statement(to_statement, statement_items)
    end

    def make_eligible_declaration_payable_for_to_statement(to_statement, statement_items)
      declarations = statement_items.map(&:declaration).uniq
      eligible_declarations = declarations.select(&:eligible?)

      return unless to_statement.payable?
      return unless eligible_declarations.any?

      service = Declarations::MarkAsPayable.new(statement: to_statement)
      action = service.class.to_s.underscore.humanize.split.last

      record_info("Marking #{eligible_declarations.size} eligible declarations as #{action} for #{to_statement.year}-#{to_statement.month} statement")

      eligible_declarations.each { |declaration| service.mark(declaration:) }
    end

    def make_payable_declaration_eligible_for_to_statement(to_statement, statement_items)
      declarations = statement_items.map(&:declaration).uniq
      payable_declarations = declarations.select(&:payable?)

      return if to_statement.payable? || to_statement.paid?
      return unless payable_declarations.any?

      record_info("Marking #{payable_declarations.size} payable declarations back as eligible for #{to_statement.year}-#{to_statement.month} statement")
      payable_declarations.each(&:mark_eligible!)
      statement_items.select(&:payable?).map(&:mark_eligible!)
    end

    def record_summary_info(dry_run)
      record_info("~~~ DRY RUN ~~~") if dry_run
      record_info("Migrating declarations from #{from_year}-#{from_month} to #{to_year}-#{to_month} for #{provider_count} providers")
    end

    def record_info(message)
      Rails.logger.info(message)
    end
  end
end
