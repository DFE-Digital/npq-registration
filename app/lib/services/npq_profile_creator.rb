module Services
  class NpqProfileCreator
    attr_reader :application

    def initialize(application:)
      @application = application
    end

    def call
      profile = EcfApi::NpqProfile.new(
        teacher_reference_number: user.trn,
        date_of_birth: user.date_of_birth,
        school_urn: application.school_urn,
        headteacher_status: application.headteacher_status,
        relationships: {
          user: ecf_user,
          npq_course: ecf_npq_course,
          npq_lead_provider: ecf_npq_lead_provider,
        },
      )

      profile.save
      application.update!(ecf_id: profile.id)
    end

  private

    def user
      application.user
    end

    def ecf_user
      @ecf_user ||= EcfApi::User.new(id: application.user.ecf_id)
    end

    def ecf_npq_course
      @ecf_npq_course ||= EcfApi::NpqCourse.new(id: application.course.ecf_id)
    end

    def ecf_npq_lead_provider
      @ecf_npq_lead_provider ||= EcfApi::NpqLeadProvider.new(id: application.lead_provider.ecf_id)
    end
  end
end
