namespace :users do
  namespace :get_an_identity_data_sync do
    desc "Schedules background job to gather updated data from GAI and sync to NPQ DB, applies only to a single user with given id"
    task :user, %i[id] => :environment do
      id = args[:id]
      Rails.logger.info "Enqueueing Sync Jobs for user with id: #{id}"

      user = User.with_get_an_identity_id # Must have a get_an_identity_id
                 .find_by(id:)

      GetAnIdentityDataSyncJob.perform_later(user:)
      Rails.logger.info "User Sync Job Enqueued for User##{user.id}"
    end

    desc "Schedules background job to gather updated data from GAI and sync to NPQ DB, applies only to users with updated_from_tra_at: nil"
    task without_updated_at: :environment do
      Rails.logger.info "Enqueueing Sync Jobs for all users without updated_from_tra_at set"

      users = User.with_get_an_identity_id # Must have a get_an_identity_id
                  .where(updated_from_tra_at: nil)

      users.find_each(batch_size: 200) do |user|
        GetAnIdentityDataSyncJob.perform_later(user:)
        Rails.logger.info "User Sync Job Enqueued for User##{user.id}"
      end
    end

    desc "Schedules background job to gather updated data from GAI and sync to NPQ DB"
    task all: :environment do
      Rails.logger.info "Enqueueing Sync Jobs for all users"

      users = User.with_get_an_identity_id # Must have a get_an_identity_id

      users.find_each(batch_size: 200) do |user|
        GetAnIdentityDataSyncJob.perform_later(user:)
        Rails.logger.info "User Sync Job Enqueued for User##{user.id}"
      end
    end
  end
end
