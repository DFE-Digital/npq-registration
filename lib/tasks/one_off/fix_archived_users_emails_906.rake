namespace :one_off do
  # https://github.com/DFE-Digital/teacher-training-entitlement-board/issues/906
  desc "Fix archived users with active email addresses"
  task :fix_archived_users, %i[dry_run log_pii] => :versioned_environment do |_t, args|
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

    dry_run = args[:dry_run] != "false"
    log_pii = args[:log_pii].presence == "true"

    logger.info "Dry run" if dry_run

    ActiveRecord::Base.transaction do
      users = User.archived.where.not(archived_email: nil).where("email = archived_email")
      users.each do |user|
        old_email = user.email
        new_email = "archived-#{user.archived_email}"
        user.update!(email: new_email, provider: nil, uid: nil)

        if log_pii
          logger.info("Updated email and blanked provider UID for user #{user.id} from #{old_email} to #{new_email}")
        else
          logger.info("Updated email and blanked provider UID for user #{user.id}")
        end
      end

      if dry_run
        logger.info "rolling back dry run"
        raise ActiveRecord::Rollback
      end
    end
  end
end
