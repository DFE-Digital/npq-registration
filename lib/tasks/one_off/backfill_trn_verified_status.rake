namespace :one_off do
  desc "Reset the TRN Verified status for users incorrectly marked as unverified"
  task :backfill_trn_verified_status, %i[dry_run] => :environment do |_task, args|
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)
    dry_run = args[:dry_run] != "false"
    issue_introduced = Date.parse("2024-11-28").at_beginning_of_day

    User.transaction do
      # Find potential affected users
      user_ids = User.where(trn_verified: false,
                            trn_auto_verified: true,
                            updated_at: issue_introduced..)
                     .limit(4000)
                     .pluck(:id)

      corrected_user_ids = []
      batch_counter = 0

      logger.info "Identified #{user_ids.length} potential users to correct"
      logger.info "DRY RUN: will roll back at end" if dry_run

      # work in batches because each user may have tens of versions
      user_ids.each_slice(200) do |batch|
        logger.info("Processing #{batch.length + 200 * batch_counter} / #{user_ids.length}")
        batch_counter += 1

        users = User.where(id: batch).includes(:versions).to_a

        users.each do |user|
          # Identify if user had problem with problem
          matching_version_changes = user.versions.select do |version|
            version.created_at > issue_introduced &&
              !version.object_changes.nil? &&
              version.object_changes["trn_verified"] == [true, false] &&
              version.object_changes.key?("updated_from_tra_at")
          end

          next if matching_version_changes.none?

          trn_got_changed = user.versions.any? do |version|
            version.created_at > issue_introduced &&
              !version.object_changes.nil? &&
              version.object_changes.key?("trn") &&
              version.object_changes["trn"][0] # changed from non-nil value
          end

          if trn_got_changed
            logger.info "Skipping User #{user.id} - TRN got changed at some point"
            next
          end

          # Code to update user
          user.update!(
            trn_verified: true,
            trn_lookup_status:
              matching_version_changes[0].object_changes["trn_lookup_status"]&.first,
          )
          corrected_user_ids << user.id
        end
      end

      logger.info "Finished, updated #{corrected_user_ids.length}"

      if dry_run
        logger.info "DRY RUN: rolling back"
        raise ActiveRecord::Rollback
      end
    end
  end
end
