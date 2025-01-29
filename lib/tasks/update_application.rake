namespace :update_application do
  desc "Accept an application"
  task :accept, %i[application_ecf_id] => :environment do |_t, args|
    logger = Logger.new($stdout)
    application = Application.find_by(ecf_id: args.application_ecf_id)
    raise "Application not found: #{args.application_ecf_id}" unless application

    service = Applications::Accept.new(application:)

    result = service.accept
    if result
      logger.info("Application #{args.application_ecf_id} accepted")
    else
      logger.error(service.errors.full_messages.to_sentence)
    end
  end

  desc "Revert an application to pending"
  task :revert_to_pending, %i[application_ecf_id] => :environment do |_t, args|
    logger = Logger.new($stdout)
    application = Application.find_by(ecf_id: args.application_ecf_id)
    raise "Application not found: #{args.application_ecf_id}" unless application

    service = Applications::RevertToPending.new(application:, change_status_to_pending: "yes")

    result = service.revert
    if result
      logger.info("Application #{args.application_ecf_id} reverted to pending")
    else
      logger.error(service.errors.full_messages.to_sentence)
    end
  end

  desc "Change the lead provider of an application"
  task :change_lead_provider, %i[application_ecf_id new_lead_provider_id] => :environment do |_t, args|
    logger = Logger.new($stdout)
    application = Application.find_by(ecf_id: args.application_ecf_id)
    raise "Application not found: #{args.application_ecf_id}" unless application

    new_lead_provider = LeadProvider.find(args.new_lead_provider_id)
    raise "Lead Provider not found: #{args.new_lead_provider_id}" unless new_lead_provider

    old_lead_provider = application.lead_provider

    application.update!(lead_provider: new_lead_provider)

    logger.error("Application #{args.application_ecf_id} lead provider changed from #{old_lead_provider.name} to #{new_lead_provider.name}")
  end
end
