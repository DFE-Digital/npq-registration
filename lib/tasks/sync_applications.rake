namespace :sync do
  desc "Sync applications attributes with ecf service"
  task applications: :environment do
    Rails.logger.info "syncing applications"

    applications = Application.where.not(ecf_id: nil)
                              .order(created_at: :asc)

    Services::Ecf::NpqProfileMassUpdater.new(applications:).call
  end

  desc "Sync applications attributes with ecf service"
  task teacher_catchments: :environment do
    Rails.logger.info "syncing application teacher catchments"

    applications = Application.where(teacher_catchment_synced_to_ecf: false)
                              .where.not(ecf_id: nil)
                              .order(created_at: :asc)

    mass_updater = Services::Ecf::NpqProfileMassUpdater.new(applications:) do |application|
      application.update_column(teacher_catchment_synced_to_ecf: true)
    end

    mass_updater.call
  end
end
