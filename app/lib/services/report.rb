require "csv"

module Services
  class Report
    def call
      CSV.generate do |csv|
        csv << headers

        applications.each do |a|
          csv << [
            a.user.id,
            a.user.ecf_id,
            a.user.created_at,
            a.user.trn_verified,
            a.user.trn_auto_verified,
            a.id,
            a.ecf_id,
            a.created_at,
            a.headteacher_status,
            a.eligible_for_funding,
            a.funding_choice,
            a.school_urn,
            a.school&.name,
            a.school&.establishment_type_name,
            a.school&.high_pupil_premium,
            a.school&.la_name,
            a.school&.postcode,
            a.course.name,
            a.lead_provider.name,
          ]
        end
      end
    end

  private

    def headers
      %w[
        user_id
        ecf_user_id
        user_created_at
        trn_verified
        trn_auto_verified
        application_id
        application_ecf_id
        application_created_at
        headteacher_status
        eligible_for_funding
        funding_choice
        school_urn
        school_name
        establishment_type_name
        high_pupil_premium
        la_name
        school_postcode
        course_name
        provider_name
      ]
    end

    def applications
      @applications = Application.includes(:user, :course, :lead_provider, :school)
    end
  end
end
