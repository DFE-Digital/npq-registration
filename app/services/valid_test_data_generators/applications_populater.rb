# frozen_string_literal: true

module ValidTestDataGenerators
  class ApplicationsPopulater
    class << self
      def populate(lead_provider:, cohort:, number_of_participants: 50)
        new(lead_provider:, cohort:, number_of_participants:).populate
      end
    end

    def populate
      return unless Rails.env.in?(%w[development review separation])

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
      user = create_user
      application = create_application(user, school, course)

      return if Faker::Boolean.boolean(true_ratio: 0.3)

      accept_application(application)
      create_declarations(application)

      return if Faker::Boolean.boolean(true_ratio: 0.3)

      course = courses.reject { |c| c.identifier == course.identifier }.sample
      application = create_application(user, school, course)

      return if Faker::Boolean.boolean(true_ratio: 0.3)

      reject_application(application)
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

    def create_declarations(application)
      %w[started retained-1 retained-2 completed].each do |declaration_type|
        break if Faker::Boolean.boolean(true_ratio: 0.5)

        FactoryBot.create(
          :declaration,
          :submitted_or_eligible,
          application:,
          declaration_type:,
        )
      end
    end
  end
end
