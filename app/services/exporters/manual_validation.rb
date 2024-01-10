class Exporters::ManualValidation
  def call
    Rails.logger.debug "application_ecf_id,trn,name,dob,nino,email"
    Application.includes(:user).where(user: { trn_verified: false }).find_each { |a| Rails.logger.debug "#{a.ecf_id},#{a.user.trn},#{a.user.full_name},#{a.user.date_of_birth},#{a.user.national_insurance_number},#{a.user.email}" }
  end
end
