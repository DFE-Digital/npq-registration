# frozen_string_literal: true

module ValidTestDataGenerators
  class ApplicationsPopulater
    class << self
      def populate(lead_provider:, cohort:, number_of_participants: 50)
        new(lead_provider:, cohort:, number_of_participants:).populate
      end
    end

    def populate
      return unless Rails.env.in?(%w[development separation])

      logger.info "ApplicationsPopulater: Started!"

      ActiveRecord::Base.transaction do
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
      @courses = Course.all.reject { |c| c.identifier == "npq-early-headship-coaching-offer" }
    end

    def create_participants!
      number_of_participants.times { create_participant(school: School.open.order("RANDOM()").first) }
    end

    def create_participant(school:)
      course = courses.sample

      user = FactoryBot.create(:user,
                               :with_get_an_identity_id,
                               :with_random_name,
                               date_of_birth: Date.new(1990, 1, 1),
                               trn: Faker::Number.unique.number(digits: 7),
                               trn_verified: true,
                               trn_auto_verified: true)

      application = FactoryBot.create(:application,
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

      methods = %i[accept_application reject_application]

      return if Faker::Boolean.boolean

      send(methods.sample, application)

      return if Faker::Boolean.boolean

      application = FactoryBot.create(:application,
                                      :pending,
                                      :with_random_work_setting,
                                      school:,
                                      lead_provider:,
                                      user:,
                                      cohort:,
                                      course: courses.reject { |c| c.identifier == course.identifier }.sample,
                                      headteacher_status: Application.headteacher_statuses.keys.sample,
                                      eligible_for_funding: Faker::Boolean.boolean,
                                      itt_provider: IttProvider.currently_approved.order("RANDOM()").first)

      return if Faker::Boolean.boolean

      send(methods.sample, application)
    end

    def accept_application(application)
      # TODO: replace by Applications::Accept.new(application:).accept when service class is added
      application.update!(lead_provider_approval_status: "accepted")
      application.reload
    end

    def reject_application(application)
      Applications::Reject.new(application:).reject
      application.reload
    end
  end
end
