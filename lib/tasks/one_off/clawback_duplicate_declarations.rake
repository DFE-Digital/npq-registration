namespace :one_off do
  desc "Clawback duplicate paid delcarations"
  task :clawback_duplicate_delcarations, %i[dry_run] => :versioned_environment do |_task, args|
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)
    dry_run = args[:dry_run] != "false"

    logger.info "Dry run:" if dry_run

    applications_with_duplicate_declarations = Application
      .joins(:declarations, :cohort)
      .where(declarations: { state: "paid" })
      .group(:id, :declaration_type)
      .having("count(applications.id) > 1")
    duplicate_declarations = applications_with_duplicate_declarations.pluck(Arel.sql("array_agg(declarations.id)"))

    Declaration.transaction do
      duplicate_declarations.each do |declaration_ids|
        declaration_id_to_clawback = declaration_ids.max
        declaration = Declaration.find(declaration_id_to_clawback)
        service = Declarations::Void.new(declaration:)
        result = service.void

        if result
          logger.info "Clawed back " \
            "declaration ECF ID: #{declaration.ecf_id}, " \
            "Cohort: #{declaration.cohort.identifier}, " \
            "Lead Provider: #{declaration.lead_provider.name}"
        else
          logger.error "Failed to claw back declaration #{declaration.id} - #{service.errors.full_messages.to_sentence}"
          raise ActiveRecord::Rollback
        end
      end

      if dry_run
        logger.info "Dry run: rolling back"
        raise ActiveRecord::Rollback
      end
    end
  end
end
