module Events
  class ApplicationAcceptance
    attr_accessor :description
    attr_reader :application, :user, :school, :private_childcare_provider, :course, :cohort, :lead_provider

    def initialize(application:, user:, course:, cohort:, lead_provider:, school: nil, private_childcare_provider: nil, title: nil, description: nil, byline: nil)
      @application = application
      @user = user
      @school = school
      @private_childcare_provider = private_childcare_provider
      @cohort = cohort
      @course = course
      @lead_provider = lead_provider

      @override_title = title
      @override_description = description
      @override_byline = byline
    end

    def self.create_event_from_application(application)
      new(
        application:,
        user: application.user,
        school: application.school,
        private_childcare_provider: application.private_childcare_provider,
        cohort: application.cohort,
        course: application.course,
        lead_provider: application.lead_provider,
      ).create_event
    end

    def title
      @override_title || "Application #{application.id} accepted"
    end

    def byline
      @override_byline || lead_provider.name
    end

    def create_event
      Event.create!(event_type:, application:, user:, school:, private_childcare_provider:, course:, cohort:, lead_provider:, title:, description:, byline:)
    end

  private

    def event_type
      "Application accepted"
    end
  end
end
