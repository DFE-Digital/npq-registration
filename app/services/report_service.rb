require "csv"
class ReportService
  def call
    CSV.generate do |csv|
      csv << headers
      applications.find_each do |application|
        csv << row_for_application(application)
      end
    end
  end

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
      funding_eligiblity_status_code
      targeted_delivery_funding_eligibility
      works_in_childcare
      kind_of_nursery
      private_childcare_provider_urn
      school_urn
      school_name
      establishment_type_name
      high_pupil_premium
      la_name
      school_postcode
      course_name
      provider_name
      employment_type
      senco_in_role
      senco_start_date
    ]
  end

private

  def row_for_application(a)
    [
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
      a.funding_eligiblity_status_code,
      a.targeted_delivery_funding_eligibility,
      a.works_in_childcare,
      a.kind_of_nursery,
      a.private_childcare_provider&.provider_urn,
      a.school_urn,
      a.school&.name,
      a.school&.establishment_type_name,
      a.school&.high_pupil_premium,
      a.school&.la_name,
      a.school&.postcode,
      a.course.name,
      a.lead_provider.name,
      a.employment_type,
      a.raw_application_data["senco_in_role"],
      a.raw_application_data["senco_start_date"],
    ]
  end

  def applications
    @applications = Application.includes(:user, :course, :lead_provider, :school, :private_childcare_provider)
  end
end
