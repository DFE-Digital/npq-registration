namespace :update_participant do
  desc "Withdraw a participant from a course"
  task :withdraw, %i[participant_ecf_id application_ecf_id reason] => :environment do |_t, args|
    logger = Logger.new($stdout)
    application = Application.find_by(ecf_id: args.application_ecf_id)
    raise "Application not found: #{args.application_ecf_id}" unless application

    reason = args.reason

    service = Participants::Withdraw.new(lead_provider: application.lead_provider,
                                         participant_id: application.user.ecf_id,
                                         course_identifier: application.course.identifier,
                                         reason:)
    result = service.withdraw

    if result
      logger.info("Participant #{args.participant_ecf_id} withdrawn from application #{args.application_ecf_id}")
    else
      logger.error(service.errors.full_messages.to_sentence)
    end
  end
end
