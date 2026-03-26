namespace :one_off do
  desc "Void/Clawback duplicate submitted/paid declarations"
  task :void_or_clawback_duplicate_declarations, %i[dry_run] => :versioned_environment do |_task, args|
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)
    dry_run = args[:dry_run] != "false"

    logger.info "Dry run:" if dry_run

    applications_with_duplicate_declarations = Application
      .joins(:declarations, :cohort)
      .where(declarations: { state: %w[submitted paid] }) # TODO: test submitted state
      .group(:id, :declaration_type, :state)
      .having("count(applications.id) > 1")
    duplicate_declarations = applications_with_duplicate_declarations.pluck(Arel.sql("array_agg(declarations.id)"))
    totals = { voided: 0, awaiting_clawback: 0 }

    Declaration.transaction do
      duplicate_declarations.each do |declaration_ids|
        declaration_id_to_clawback = declaration_ids.max
        declaration = Declaration.find(declaration_id_to_clawback)
        service = Declarations::Void.new(declaration:)
        result = service.void

        if result
          totals[declaration.state.to_sym] += 1
          logger.info "declaration #{declaration.state} - " \
            "ECF ID: #{declaration.ecf_id}, " \
            "Cohort: #{declaration.cohort.identifier}, " \
            "Lead Provider: #{declaration.lead_provider.name}"
        else
          logger.error "Failed to claw back declaration #{declaration.id} - #{service.errors.full_messages.to_sentence}"
          raise ActiveRecord::Rollback
        end
      end

      logger.info "Totals: #{totals.map { |k, v| "#{k}: #{v}" }.join(", ")}"

      if dry_run
        logger.info "Dry run: rolling back"
        raise ActiveRecord::Rollback
      end
    end
  end
end
