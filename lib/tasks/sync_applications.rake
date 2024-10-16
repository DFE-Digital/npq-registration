namespace :sync do
  desc "Sync applications attributes with ecf service"
  task applications: :environment do
    Rails.logger.info "syncing applications"

    applications = Application.where.not(ecf_id: nil)
                              .order(created_at: :asc)

    Ecf::NpqProfileMassUpdater.new(applications:).call
  end

  desc "Sync applications attributes with ecf service"
  task teacher_catchments: :environment do
    Rails.logger.info "syncing application teacher catchments"

    applications = Application.where(teacher_catchment_synced_to_ecf: false)
                              .where.not(ecf_id: nil)
                              .order(created_at: :asc)

    mass_updater = Ecf::NpqProfileMassUpdater.new(applications:) do |application|
      application.update_column(:teacher_catchment_synced_to_ecf, true)
    end

    mass_updater.call
  end

  desc "Sync tsf primary attributes of application with ecf service"
  task :tsf_primary_attributs, [:offset] => :environment do |_task, args|
    Rails.logger.info "syncing applications"
    offset = args[:offset].to_i || 0 # Default offset to 0 if not provided

    applications = Application.where.not(number_of_pupils: 0)
                              .or(Application.where.not(primary_establishment: false))
                              .or(Application.where.not(tsf_primary_plus_eligibility: false))
                              .order(created_at: :asc)
                              .offset(offset).limit(2000)

    Ecf::TsfMassDataFieldUpdater.new(applications:).call
  end
end
