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

        logger.info("Application #{args.application_ecf_id} lead provider changed from #{old_lead_provider.name} to #{new_lead_provider.name}")
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

      desc "Change cohort on an application"
      task :change_cohort, %i[application_ecf_id new_cohort_year override_declarations_check] => :environment do |_t, args|
        find_application(args.application_ecf_id)

        new_cohort = Cohort.find_by(start_year: args.new_cohort_year)
        raise "Cohort not found: #{args.new_cohort_year}" unless new_cohort

        cohort_before_update = application.cohort.start_year

        override_declarations_check = args.override_declarations_check == "true"
        service = Applications::ChangeCohort.new(application:, cohort_id: new_cohort.id, override_declarations_check:)
        result = service.change_cohort
        raise service.errors.messages.values.flatten.to_sentence unless result

        logger.info("Application #{application.ecf_id} cohort changed from #{cohort_before_update} to #{application.cohort.start_year}")
      end

      desc "Change the schedule on an application"
      task :update_schedule, %i[application_ecf_id new_schedule_identifier] => :environment do |_t, args|
        find_application(args.application_ecf_id)

        raise "Cannot change schedule for an application with declarations" if application.declarations.any?

        current_schedule = application.schedule

        new_schedule = Schedule.find_by(identifier: args.new_schedule_identifier, cohort: application.cohort)
        raise "Schedule not found: #{args.new_schedule_identifier}" unless new_schedule

        application.update!(schedule: new_schedule)
        logger.info("Application #{application.ecf_id} schedule changed from '#{current_schedule&.identifier}' to '#{new_schedule.identifier}'")
      end

      desc "Update Participant on an application (and move declarations)"
      task :update_participant, %i[application_ecf_id new_participant_ecf_id] => :environment do |_t, args|
        find_application(args.application_ecf_id)

        old_user = application.user

        new_user = User.find_by(ecf_id: args.new_participant_ecf_id)
        raise "User not found: #{args.new_participant_ecf_id}" unless new_user

        application.update!(user: new_user)

        logger.info("Application #{application.ecf_id} participant changed from #{old_user.ecf_id} to #{new_user.ecf_id}")
      end
    end
  end

private

  def logger
    @logger ||= Rails.env.test? ? Rails.logger : Logger.new($stdout)
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
