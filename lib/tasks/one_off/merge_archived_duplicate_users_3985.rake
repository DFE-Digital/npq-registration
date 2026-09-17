# Merges the archived users with a blank email (shown on the Archived duplicate users screen)
# into the not archived TeacherAuth user with the same verified TRN.
# These should have been merged by the TRS webhooks, but were not because they were already archived.
# usage:
# for dry run: rake 'one_off:merge_archived_duplicate_users'
# for real run: rake 'one_off:merge_archived_duplicate_users[false]'
namespace :one_off do
  desc "One off task for ticket NPQ-3985 to merge archived duplicate users into the user with the same verified TRN"
  task :merge_archived_duplicate_users, %i[dry_run] => :versioned_environment do |_task, args|
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)
    dry_run = args[:dry_run] != "false"

    logger.info "DRY RUN: nothing will be saved" if dry_run

    archived_duplicate_users = User
      .archived
      .where(email: nil, trn_verified: true)
      .where.not(trn: nil)
      .joins(:applications)
      .distinct

    merged_count = 0
    skipped_count = 0

    archived_duplicate_users.find_each do |user_to_merge|
      users_to_keep = User.not_archived.with_teacher_auth.with_trn(user_to_merge.trn).to_a

      if users_to_keep.size != 1
        logger.info "Skipping user #{user_to_merge.ecf_id}: found #{users_to_keep.size} not archived TeacherAuth users with TRN #{user_to_merge.trn}"
        skipped_count += 1
        next
      end

      user_to_keep = users_to_keep.first
      logger.info "Merging user #{user_to_merge.ecf_id} into user #{user_to_keep.ecf_id}"
      Users::MergeAndArchive.new(user_to_merge:, user_to_keep:, logger:).call(dry_run:, allow_archived_users: true)
      merged_count += 1
    end

    logger.info "Merged users: #{merged_count}, skipped users: #{skipped_count}"
  end
end
