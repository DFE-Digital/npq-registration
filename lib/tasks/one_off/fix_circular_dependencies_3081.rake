namespace :one_off do
  desc "One off task for deleting stale ParticipantIdChange"
  task delete_empty_participant_id_changes: :environment do
    User.joins(:participant_id_changes).where("archived_email is null").where("participant_id_changes.from_participant_id = users.ecf_id").find_each do |from_user|
      change = ParticipantIdChange.find_by(from_participant_id: from_user.ecf_id)
      to_user = User.find_by(ecf_id: change.to_participant_id)

      if to_user.nil?
        ParticipantIdChange.where(from_participant_id: change.to_participant_id, to_participant_id: from_user.ecf_id).delete_all
        change.destroy!
      end
    end
  end

  desc "One off task for fixing ParticipantIdChange circular dependencies"
  task fix_participant_id_changes_circular_dependencies: :environment do
    ActiveRecord::Base.transaction do
      User.joins(:participant_id_changes).where("archived_email is null").where("participant_id_changes.from_participant_id = users.ecf_id").find_each do |from_user|
        change = ParticipantIdChange.find_by(from_participant_id: from_user.ecf_id)
        to_user = User.find_by(ecf_id: change.to_participant_id)

        next unless to_user

        next unless to_user.trn == from_user.trn

        ParticipantIdChange.where(from_participant_id: change.to_participant_id, to_participant_id: from_user.ecf_id).destroy_all
        change.destroy!

        if to_user.significantly_updated_at > from_user.significantly_updated_at
          Users::MergeAndArchive.new(user_to_merge: from_user, user_to_keep: to_user).call(dry_run: false)
        else
          Users::MergeAndArchive.new(user_to_merge: to_user, user_to_keep: from_user).call(dry_run: false)
        end
      end
    end
  end
end
