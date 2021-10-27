class Services::Exporters::ManualValidation
  def call
    puts "application_ecf_id,trn,name,dob,nino"
    Application.includes(:user).where(user: { trn_verified: false }).each { |a| puts "#{a.ecf_id},#{a.user.trn},#{a.user.full_name},#{a.user.date_of_birth},#{a.user.national_insurance_number}" }
  end
end
