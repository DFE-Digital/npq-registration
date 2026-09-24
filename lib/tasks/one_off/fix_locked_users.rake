namespace :one_off do
  desc "Fix"
  task :fix_locked_users, %i[dry_run log_pii] => :versioned_environment do |_t, args|
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

    dry_run = args[:dry_run] != "false"
    log_pii = args[:log_pii].presence == "true"

    locked_users = File.read("config/data/locked_users.txt").split("\n").map(&:to_i)

    user_list_a = [1716, 1411, 91, 175, 33_282, 2156, 1982, 1931, 3058, 236, 256, 410, 124, 1996, 1115, 2592, 1321, 145_941, 1820, 1994, 264, 3164, 1947, 2915, 949, 344, 2055, 7, 8, 2471, 17, 774, 1216, 972, 1960, 27_234, 1603, 3160, 67, 46, 47, 212, 70_160, 81]

    user_list_b = [172_152, 163_589, 175_120, 145_193, 160_209, 125_641, 117_298, 116_425, 81_962, 87_442, 90_267, 157_643, 165_359, 100_422, 128_886, 182_613, 181_625, 94_073, 175_025, 153_459, 177_432, 9979, 122_204, 104_346, 81_671, 168_323, 1216, 75_109, 174_019, 22_955, 171_863, 174_599, 113_902, 175_907]

    applications = [207_794, 196_310, 212_414, 171_561, 193_228, 145_893, 210_474, 135_672, 135_681, 134_636, 137_187, 93_920, 111_346, 103_387, 208_243, 215_162, 115_480, 179_856, 219_242, 107_584, 183_689, 212_931, 217_367, 10_257, 141_665, 141_674, 120_310, 93_580, 85_521, 211_928, 24_921, 209_002, 211_572, 211_577, 131_706, 133_122]
    user_list = user_list_a + user_list_b

    extra_user_ids = locked_users - user_list

    trn_update_ids = []
    archived_update_ids = []

    whodunnit = "Background job: GetAnIdentity::ProcessWebhookMessageJob"

    user_list.each do |user_id|
      user = User.where(id: user_id).first

      trn_versions = user.versions.where(whodunnit:).select { |v| v.object_changes.keys.include?("trn") }
      trn_update_ids << user_id if trn_versions.any?

      archived_versions = user.versions.where(whodunnit:).select { |v| v.object_changes.keys.include?("archived_email") }
      archived_update_ids << user_id if archived_versions.any?
    end

    logger.info " ~~~ Dry Run ~~~ " if dry_run
    logger.info "--------------------"
    logger.info "Check lists all have papertrail of updates from GetAnIdentity::ProcessWebhookMessageJob:"
    logger.info "--------------------"
    logger.info "A, B lists #{user_list_a.uniq.count}, #{user_list_b.uniq.count}"
    logger.info "Applications #{applications.uniq.count}"
    logger.info ""
    logger.info "TRN update IDs (#{trn_update_ids.uniq.count}): #{trn_update_ids.join(', ')}"
    logger.info ""
    logger.info "Archived update IDs (#{archived_update_ids.uniq.count}): #{archived_update_ids.join(', ')}"
    logger.info ""
    logger.info "Extra user IDs in locked_users.txt (#{extra_user_ids.uniq.count}): #{extra_user_ids.uniq.join(', ')}"
    logger.info "--------------------"

    ActiveRecord::Base.transaction do
      # list A: revert TRN updates
      user_list_a.each do |user_id|
        user = User.find(user_id)
        first_trn_version = user.versions.where(whodunnit:).select { |v| v.object_changes.keys.include?("trn") }.first
        original_values = first_trn_version.object_changes.transform_values(&:first)
        logger.info "Reverting values for user ID=#{user_id}: #{original_values} using values from version ID=#{first_trn_version.id} created_at=#{first_trn_version.created_at}"
        user.update!(original_values)
      end

      logger.info "--------------------"

      # list B: unarchive users
      user_list_b.each do |user_id|
        user = User.find(user_id)
        unarchived_versions = user.versions.where(whodunnit:).select { |v| v.object_changes.keys.include?("archived_email") }
        last_unarchived_version = unarchived_versions.last

        original_values = last_unarchived_version.object_changes.transform_values(&:first)
        if log_pii
          logger.info "Unarchiving user ID=#{user_id}: #{original_values} using values from version ID=#{last_unarchived_version.id} created_at=#{last_unarchived_version.created_at}"
        else
          logger.info "Unarchiving user ID=#{user_id} using values from version ID=#{last_unarchived_version.id} created_at=#{last_unarchived_version.created_at}"
        end
        logger.info "User ID=#{user_id} had #{unarchived_versions.count} unarchive versions, used the last one" if unarchived_versions.count > 1
        user.update!(original_values)
      end

      logger.info "--------------------"

      # applications list: move back to original users
      applications.each do |application_id|
        application = Application.find(application_id)
        user_id_versions = application.versions.where(whodunnit:).select { |v| v.object_changes.keys.include?("user_id") }
        first_user_id_version = user_id_versions.first

        original_user_id = first_user_id_version.object_changes["user_id"].first
        logger.info "Moving application ID=#{application_id} back to original user ID=#{original_user_id} using values from version ID=#{first_user_id_version.id} created_at=#{first_user_id_version.created_at}"

        raise "user not unarchived" if User.find(original_user_id).archived?

        last_participant_id_change = application.participant_id_changes.last

        if last_participant_id_change
          raise "last participant_id_change is wrong one" if User.find_by(ecf_id: last_participant_id_change.from_participant_id).id != original_user_id &&
            User.find_by(ecf_id: last_participant_id_change.to_participant_id).id != first_user_id_version.object_changes["user_id"].last

          logger.info "Removing participant_id_change ID=#{application.participant_id_changes.last.id}"
          last_participant_id_change.destroy!
        else
          logger.info "Application ID=#{application_id} has no participant_id_changes"
        end
      end

      if dry_run
        logger.info "--------------------"
        logger.info "rolling back dry run"
        raise ActiveRecord::Rollback
      end
    end

    logger.info "--------------------"
    logger.info "done."
  end
end
