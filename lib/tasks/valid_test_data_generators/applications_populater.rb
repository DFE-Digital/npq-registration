# frozen_string_literal: true

require "tasks/valid_test_data_generators/school_urn_generator"
require "tasks/valid_test_data_generators/trn_generator"

module ValidTestDataGenerators
  class ApplicationsPopulater
    class << self
      def populate(lead_provider:, cohort:, total_schools: 10, participants_per_school: 50)
        new(lead_provider:, cohort:, participants_per_school:).populate(total_schools:)
      end
    end

    def populate(total_schools: 10)
      return unless Rails.env.in?(%w[development separation])

      logger.info "ApplicationsPopulater: Started!"

      ActiveRecord::Base.transaction do
        generate_new_schools!(count: total_schools)
      end

      logger.info "ApplicationsPopulater: Finished!"
    end

  private

    attr_reader :lead_provider, :cohort, :participants_per_school, :courses, :logger

    def initialize(lead_provider:, cohort:, participants_per_school:, logger: Rails.logger)
      @lead_provider = lead_provider
      @cohort = cohort
      @participants_per_school = participants_per_school
      @logger = logger
      @courses = Course.all.reject { |c| c.identifier == "npq-early-headship-coaching-offer" }
    end

    def generate_new_schools!(count:)
      count.times { create_school_with(urn: SchoolURNGenerator.next) }
    end

    def find_or_create_participants(school:, number_of_participants:)
      generate_new_participants(school:, count: number_of_participants)
    end

    def generate_new_participants(school:, count:)
      count.times do
        create_participant(school:)
      end
    end

    def create_participant(school:)
      name = Faker::Name.name
      trn = TRNGenerator.next
      course = courses.sample

      user = User.create!(
        full_name: name,
        email: Faker::Internet.email(name:),
        date_of_birth: Date.new(1990, 1, 1),
        trn:,
        trn_verified: true,
        trn_auto_verified: true,
        ecf_id: SecureRandom.uuid,
        get_an_identity_id: SecureRandom.uuid,
      )

      application = Application.create!(
        eligible_for_funding: [true, false].sample,
        lead_provider_approval_status: "pending",
        school:,
        lead_provider:,
        user:,
        cohort:,
        course:,
        ecf_id: SecureRandom.uuid,
        works_in_school: true,
        works_in_childcare: false,
        funding_choice: Application.funding_choices.keys.sample,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        headteacher_status: Application.headteacher_statuses.keys.sample,
        work_setting: %w[a_school an_academy_trust a_16_to_19_educational_setting].sample,
        lead_mentor: [true, false].sample,
      )

      methods = %i[accept_application reject_application]

      return if [true, false].sample

      send(methods.sample, application)

      return if [true, false].sample

      application = Application.create!(
        eligible_for_funding: [true, false].sample,
        lead_provider_approval_status: "pending",
        school:,
        lead_provider:,
        user:,
        cohort:,
        course: courses.reject { |c| c.identifier == course.identifier }.sample,
        ecf_id: SecureRandom.uuid,
        works_in_school: true,
        works_in_childcare: false,
        funding_choice: Application.funding_choices.keys.sample,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        headteacher_status: Application.headteacher_statuses.keys.sample,
        work_setting: %w[a_school an_academy_trust a_16_to_19_educational_setting].sample,
        lead_mentor: [true, false].sample,
      )

      return if [true, false].sample

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

    def create_school_with(urn:)
      school = School.find_or_create_by!(urn:) do |s|
        s.name = Faker::Company.name
        s.address_1 = Faker::Address.street_address
        s.postcode = Faker::Address.postcode
      end
      find_or_create_participants(school:, number_of_participants: participants_per_school)
    end
  end
end
