namespace :users do
  namespace :get_an_identity_id_sync do
    desc "Output stats on get_an_identity_id syncing"
    task stats: :environment do
      all_eligible_users = User.synced_to_ecf # Must have an ecf_id
                  .with_get_an_identity_id # Must have a get_an_identity_id

      unsynced_users = all_eligible_users.where(get_an_identity_id_synced_to_ecf: false).count
      synced_users = all_eligible_users.where(get_an_identity_id_synced_to_ecf: true).count

      Rails.logger.info("Get an Identity ID sync stats")
      Rails.logger.info("Users to sync: #{unsynced_users}")
      Rails.logger.info("Users already synced: #{synced_users}")
    end

    desc "Sends update requests to ECF for all users, setting their get_an_identity_id on ECF to the one on NPQ"
    task all: :environment do
      Rails.logger.info "Enqueueing Sync Jobs for all users"

      users = User.synced_to_ecf # Must have an ecf_id
                  .with_get_an_identity_id # Must have a get_an_identity_id
                  .where(get_an_identity_id_synced_to_ecf: false) # Must not have already been synced

      users.each do |user|
        GetAnIdentityIdSyncJob.perform_later(user:)
        Rails.logger.info "User Sync Job Enqueued for User##{user.id}"
      end
    end

    desc "Sends update request to ECF for given user, setting their get_an_identity_id on ECF to the one on NPQ"
    task :user, %i[id] => :environment do
      id = args.id
      Rails.logger.info "Enqueueing Sync Job for User##{id}"

      users = User.synced_to_ecf.with_get_an_identity_id

      user = users.find_by(id:)

      if user.present?
        GetAnIdentityIdSyncJob.perform_later(user:)
        Rails.logger.info "User Sync Job Enqueued for User##{user.id}"
      else
        Rails.logger.info "User with matching ID not found. Does this record have an ecf_id and get_an_identity_id?"
      end
    end
  end

  namespace :get_an_identity_data_sync do
    desc "Schedules background job to gather updated data from GAI and sync to NPQ DB and to ECF, applies only to users with updated_from_tra_at: nil"
    task :user, %i[id] => :environment do
      id = args[:id]
      Rails.logger.info "Enqueueing Sync Jobs for user with id: #{id}"

      user = User.synced_to_ecf # Must have an ecf_id
                 .with_get_an_identity_id # Must have a get_an_identity_id
                 .find_by(id:)

      GetAnIdentityDataSyncJob.perform_now(user:)
      Rails.logger.info "User Sync Job Enqueued for User##{user.id}"
    end

    desc "Schedules background job to gather updated data from GAI and sync to NPQ DB and to ECF, applies only to users with updated_from_tra_at: nil"
    task without_updated_at: :environment do
      Rails.logger.info "Enqueueing Sync Jobs for all users without updated_from_tra_at set"

      users = User.synced_to_ecf # Must have an ecf_id
                  .with_get_an_identity_id # Must have a get_an_identity_id
                  .where(updated_from_tra_at: nil)

      users.each do |user|
        GetAnIdentityDataSyncJob.perform_now(user:)
        Rails.logger.info "User Sync Job Enqueued for User##{user.id}"
      end
    end

    desc "Schedules background job to gather updated data from GAI and sync to NPQ DB and to ECF"
    task all: :environment do
      Rails.logger.info "Enqueueing Sync Jobs for all users"

      users = User.synced_to_ecf # Must have an ecf_id
                  .with_get_an_identity_id # Must have a get_an_identity_id

      users.each do |user|
        GetAnIdentityDataSyncJob.perform_now(user:)
        Rails.logger.info "User Sync Job Enqueued for User##{user.id}"
      end
    end
  end
end
