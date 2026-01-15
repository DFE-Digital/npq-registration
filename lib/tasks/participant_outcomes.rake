namespace :participant_outcomes do
  desc "Create a participant outcome"
  task :create, %i[user_ecf_id lead_provider_ecf_id course_identifier completion_date state] => :environment do |_t, args|
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

    user = User.find_by(ecf_id: args.user_ecf_id)
    raise "User not found: #{args.user_ecf_id}" unless user

    lead_provider = LeadProvider.find_by(ecf_id: args.lead_provider_ecf_id)
    raise "Lead provider not found: #{args.lead_provider_ecf_id}" unless lead_provider

    state = args.state || "passed"

    participant_outcome_creator = ParticipantOutcomes::Create.new(
      participant_id: user.ecf_id,
      lead_provider:,
      course_identifier: args.course_identifier,
      completion_date: args.completion_date,
      state:,
    )

    participant_outcome_creator.create_outcome
    created_outcome = participant_outcome_creator.created_outcome

    if participant_outcome_creator.valid?
      logger.info(
        "Participant outcome created/found for user #{created_outcome.user.ecf_id} " \
        "with lead provider #{created_outcome.lead_provider.name} " \
        "for course #{created_outcome.course.identifier} " \
        "with completion date #{created_outcome.completion_date} " \
        "and state #{created_outcome.state} " \
        "with created_at #{created_outcome.created_at} " \
        "and ID #{created_outcome.id}",
      )
    else
      logger.info("Could not create participant outcome")
      raise participant_outcome_creator.errors.messages.values.flatten.to_sentence
    end
  end

  desc "Void a duplicate participant outcome"
  task :void_duplicate, %i[participant_outcome_id] => :environment do |_t, args|
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

    participant_outcome = ParticipantOutcome.find_by(id: args.participant_outcome_id)
    raise "Participant outcome not found: #{args.participant_outcome_id}" unless participant_outcome

    duplicate_participant_outcomes =
      participant_outcome.declaration.participant_outcomes
      .where.not(id: participant_outcome.id)
      .where(state: ParticipantOutcome.states[:passed])

    raise "Duplicate participant outcome not found" if duplicate_participant_outcomes.empty?

    participant_outcome.update!(state: ParticipantOutcome.states[:voided])

    logger.info(
      "Participant outcome with ID #{participant_outcome.id} voided for user #{participant_outcome.user.ecf_id} " \
      "for course #{participant_outcome.course.identifier} " \
      "with completion date #{participant_outcome.completion_date}",
    )
  end
end
