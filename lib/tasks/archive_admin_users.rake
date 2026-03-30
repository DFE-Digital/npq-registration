desc "Archive admin users"
task :archive_admin_users, %i[admin_emails_csv dry_run] => :versioned_environment do |_t, args|
  logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)
  dry_run = args[:dry_run] != "false"

  logger.info "Dry run" if dry_run

  Admin.transaction do
    CSV.foreach(args[:admin_emails_csv], headers: false) do |row|
      email = row[0]
      Admin.find_by(email: email).archive!
      logger.info "Admin user with email #{email} archived."
    end

    if dry_run
      logger.info "Dry run: rolling back"
      raise ActiveRecord::Rollback
    end
  end
end
