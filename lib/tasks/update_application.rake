class UpdateApplicationRakeTask
  include Rake::DSL

  attr_reader :application

  def initialize
    namespace :update_application do
      desc "Accept an application"
      task :accept, %i[application_ecf_id] => :environment do |_t, args|
        find_application(args.application_ecf_id)

        service = Applications::Accept.new(application:)

        result = service.accept
        log_result("Application #{args.application_ecf_id} accepted", result, service.errors)
      end

      desc "Revert an application to pending"
      task :revert_to_pending, %i[application_ecf_id] => :environment do |_t, args|
        find_application(args.application_ecf_id)

        service = Applications::RevertToPending.new(application:, change_status_to_pending: "yes")

        result = service.revert
        log_result("Application #{args.application_ecf_id} reverted to pending", result, service.errors)
      end

      desc "Change the lead provider of an application"
      task :change_lead_provider, %i[application_ecf_id new_lead_provider_id] => :environment do |_t, args|
        find_application(args.application_ecf_id)

        new_lead_provider = LeadProvider.find(args.new_lead_provider_id)
        raise "Lead Provider not found: #{args.new_lead_provider_id}" unless new_lead_provider

        old_lead_provider = application.lead_provider

        application.update!(lead_provider: new_lead_provider)

        logger.error("Application #{args.application_ecf_id} lead provider changed from #{old_lead_provider.name} to #{new_lead_provider.name}")
      end

      desc "Withdraw an application"
      task :withdraw, %i[application_ecf_id reason] => :environment do |_t, args|
        find_application(args.application_ecf_id)

        reason = args.reason

        service = Participants::Withdraw.new(lead_provider: application.lead_provider,
                                             participant_id: application.user.ecf_id,
                                             course_identifier: application.course.identifier,
                                             reason:)
        result = service.withdraw
        log_result("Participant #{application.user.ecf_id} withdrawn from application #{args.application_ecf_id}", result, service.errors)
      end
    end
  end

private

  def logger
    @logger ||= Logger.new($stdout)
  end

  def find_application(ecf_id)
    @application = Application.find_by(ecf_id: ecf_id)
    raise "Application not found: #{ecf_id}" unless application
  end

  def log_result(message, result, errors)
    if result
      logger.info(message)
    else
      logger.error(errors.full_messages.to_sentence)
    end
  end
end

UpdateApplicationRakeTask.new
