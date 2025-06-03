namespace :update_legacy_passed_participant_outcomes do
  desc "Update TRNs for legacy passed participant outcomes"
  task :update_trn, %i[old_trn new_trn] => :environment do |_t, args|
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

    raise "Missing required argument: old_trn" unless args.old_trn
    raise "Missing required argument: new_trn" unless args.new_trn

    legacy_outcomes_to_update = LegacyPassedParticipantOutcome.where(trn: args.old_trn).all
    count = legacy_outcomes_to_update.count
    outcome_s = "outcome".pluralize(count)

    raise "No legacy passed participant outcomes found with TRN: #{args.old_trn}" if count.zero?

    logger.info "Updating TRN from #{args.old_trn} to #{args.new_trn} for #{count} legacy passed participant #{outcome_s}"

    LegacyPassedParticipantOutcome.transaction do
      outcome_ids = legacy_outcomes_to_update.pluck(:id)
      legacy_outcomes_to_update.update_all(trn: args.new_trn)
      logger.info "Updated TRN for legacy passed participant #{outcome_s} with #{"ID".pluralize(count)}: " \
        "#{outcome_ids.join(', ')}"
      logger.info "#{count} legacy passed participant #{outcome_s} updated."
    end
  end
end
