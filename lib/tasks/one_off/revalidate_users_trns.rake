namespace :one_off do
  desc "One off task to revalidate users TRNs using DQT API"
  task :revalidate_users_trns, %i[dry_run] => :versioned_environment do |_t, args|
    dry_run = args[:dry_run] != "false"

    Rails.logger = Logger.new($stdout) unless Rails.env.test?
    Rails.logger.level = Logger::WARN # set to 'warn' to avoid seeing 'info' logs from Dqt::V1::Teacher

    Rails.logger.warn "Dry Run" if dry_run

    users = User.distinct.joins(:applications).where(trn_verified: false, applications: { lead_provider_approval_status: "accepted" })
    users_updated = []

    User.transaction do
      users.each do |user|
        record = ParticipantValidator.new(
          trn: user.trn,
          full_name: user.full_name,
          date_of_birth: user.date_of_birth,
          national_insurance_number: user.national_insurance_number,
        ).call

        next unless record

        user.update!(
          trn: record.trn,
          trn_verified: true,
          trn_auto_verified: true,
          active_alert: record.active_alert,
          national_insurance_number: nil,
        )

        trn_changed = user.previous_changes.keys.include?("trn") ? "Yes" : "No"
        users_updated << CSV.generate_line([user.id, user.ecf_id, trn_changed, user.applications.includes(:cohort).pluck(:"cohort.identifier").join(";")])
      end

      Rails.logger.warn "Users updated:\nuser_id,user_ecf_id,trn_changed?,cohorts\n#{users_updated.join}"
      Rails.logger.warn "\nTotal users updated: #{users_updated.length}"

      if dry_run
        Rails.logger.warn "DRY RUN: Rolling back"
        raise ActiveRecord::Rollback
      end
    end
  end
end
