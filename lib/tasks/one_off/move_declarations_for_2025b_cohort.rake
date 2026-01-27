namespace :one_off do
  # for dry run: rake 'one_off:move_declarations_for_2025b_cohort'
  # for real run: rake 'one_off:move_declarations_for_2025b_cohort[false]'
  desc "Move declarations for 2025b cohort (NPQ-3496)"
  task :move_declarations_for_2025b_cohort, %i[dry_run] => :versioned_environment do |_task, args|
    Rails.logger = Logger.new($stdout) unless Rails.env.test?
    dry_run = args[:dry_run] != "false"

    Rails.logger.info("Dry run") if dry_run

    ActiveRecord::Base.transaction do
      cohort = Cohort.find_by(start_year: 2025, identifier: "2025b")
      from_month = 9
      to_month = 2
      from_statements = Statement.where(cohort:, month: from_month, year: 2026)
      to_statements = Statement.where(cohort:, month: to_month, year: 2026)

      statement_items = StatementItem
        .joins(:declaration)
        .where(statement: from_statements, state: "eligible")
        .where("declarations.created_at < ?", Date.new(2026, 1, 24))

      LeadProvider.find_each do |lead_provider|
        from_statement = from_statements.find_by(lead_provider:)
        to_statement = to_statements.find_by(lead_provider:)
        next unless from_statement && to_statement

        items_to_move = statement_items.where(statement: from_statement)

        Rails.logger.info("Migrating #{items_to_move.size} declarations for #{lead_provider.name} - from statement #{from_statement.id} to statement #{to_statement.id}")

        items_to_move.update!(statement_id: to_statement.id)
        Rails.logger.info("Marking #{items_to_move.size} declarations as payable for #{to_statement.year}-#{to_statement.month} statement: #{to_statement.id}")
        items_to_move.map(&:declaration).uniq.each do |declaration|
          service = Declarations::MarkAsPayable.new(statement: to_statement)
          service.mark(declaration:)
        end
        Rails.logger.info("Declaration IDs:\n#{items_to_move.map { |si| si.declaration.ecf_id }.join("\n")}")
      end

      raise ActiveRecord::Rollback if dry_run
    end
  end
end
