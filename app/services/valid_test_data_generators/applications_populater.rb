# frozen_string_literal: true

require "active_support/testing/time_helpers"

module ValidTestDataGenerators
  class ApplicationsPopulater
    include ActiveSupport::Testing::TimeHelpers

    class << self
      def populate(lead_provider:, cohort:, number_of_participants: 50)
        new(lead_provider:, cohort:, number_of_participants:).populate
      end
    end

    def populate
      return unless Rails.env.in?(%w[development review separation])

      logger.info "ApplicationsPopulater: Started!"

      ActiveRecord::Base.transaction do
        prepare_cohort!
        create_participants!
      end

      logger.info "ApplicationsPopulater: Finished!"
    end

  private

    attr_reader :lead_provider, :cohort, :number_of_participants, :courses, :logger

    def initialize(lead_provider:, cohort:, number_of_participants:, logger: Rails.logger)
      @lead_provider = lead_provider
      @cohort = cohort
      @number_of_participants = number_of_participants
      @logger = logger
      @courses = Course.all.reject { |c| c.identifier == "npq-additional-support-offer" }
    end

    def create_participants!
      number_of_participants.times do
        travel_to(rand(3.years.ago..Time.zone.now)) do
          create_participant(school: School.open.order("RANDOM()").first)
        end
      end
    end

    def prepare_cohort!
      cohort.tap do |c|
        c.funding_cap = cohort.start_year >= Cohort.current.start_year
        c.save!
      end
    end

    def create_participant(school:)
      course = courses.sample
      user = create_user
      application = create_application(user, school, course)

      return if Faker::Boolean.boolean(true_ratio: 0.3)

      accept_application(application)
      create_participant_id_change(application)
      create_declarations(application)
      create_outcomes(application)
      void_completed_declaration_for(application)

      return if Faker::Boolean.boolean(true_ratio: 0.3)

      if Faker::Boolean.boolean(true_ratio: 0.5)
        defer_application(application)
      else
        withdrawn_application(application)
      end

      return if Faker::Boolean.boolean(true_ratio: 0.3)

      course = courses.reject { |c| c.identifier == course.identifier }.sample
      application = create_application(user, school, course)

      return if Faker::Boolean.boolean(true_ratio: 0.3)

      reject_application(application)
    end

    def create_participant_id_change(application)
      return if Faker::Boolean.boolean(true_ratio: 0.3)

      user = application.user
      FactoryBot.create(:participant_id_change, to_participant: user, user:)
    end

    def create_user
      FactoryBot.create(:user,
                        :with_get_an_identity_id,
                        :with_random_name,
                        date_of_birth: Date.new(1990, 1, 1),
                        trn: Faker::Number.unique.number(digits: 7),
                        trn_verified: true,
                        trn_auto_verified: true)
    end

    def create_application(user, school, course)
      FactoryBot.create(:application,
                        :pending,
                        :with_random_work_setting,
                        school:,
                        lead_provider:,
                        user:,
                        cohort:,
                        course:,
                        headteacher_status: Application.headteacher_statuses.keys.sample,
                        eligible_for_funding: Faker::Boolean.boolean,
                        itt_provider: IttProvider.currently_approved.order("RANDOM()").first)
    end

    def accept_application(application)
      funded_place = if application.cohort.funding_cap?
                       application.eligible_for_funding? ? Faker::Boolean.boolean(true_ratio: 0.7) : false
                     end

      Applications::Accept.new(application:, funded_place:).accept
      application.reload
    end

    def reject_application(application)
      Applications::Reject.new(application:).reject
      application.reload
    end

    def defer_application(application)
      Participants::Defer.new(lead_provider:,
                              participant: application.user,
                              course_identifier: application.course.identifier,
                              reason: Participants::Defer::DEFERRAL_REASONS.sample).defer
    end

    def withdrawn_application(application)
      Participants::Withdraw.new(lead_provider:,
                                 participant: application.user,
                                 course_identifier: application.course.identifier,
                                 reason: Participants::Withdraw::WITHDRAWAL_REASONS.sample).withdraw
    end

    def create_declarations(application)
      %w[started retained-1 retained-2 completed].each do |declaration_type|
        break if Faker::Boolean.boolean(true_ratio: 0.5)

        FactoryBot.create(
          :declaration,
          state: Declaration.states.keys.sample,
          application:,
          declaration_type:,
        )
      end
    end

    def create_outcomes(application)
      completed_declaration = application.declarations.eligible_for_outcomes(lead_provider, application.course.identifier).first
      return unless completed_declaration
      return unless CourseGroup.joins(:courses).leadership_or_specialist.where(courses: { identifier: application.course.identifier }).exists?

      ParticipantOutcomes::Create::STATES.reverse.each do |state_trait|
        FactoryBot.create(
          :participant_outcome,
          state_trait,
          declaration: completed_declaration,
          completion_date: completed_declaration.declaration_date,
        )

        break if Faker::Boolean.boolean(true_ratio: 0.2)
      end
    end

    def void_completed_declaration_for(application)
      return if Faker::Boolean.boolean(true_ratio: 0.3)

      completed_declaration = application.declarations.eligible_for_outcomes(lead_provider, application.course.identifier).first
      Declarations::Void.new(declaration: completed_declaration).void
    end
  end
end
