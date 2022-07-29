require "csv"

class Services::Exporters::ManualValidation
  def call
    puts "application_ecf_id,trn,name,dob,nino,email"
    query.each { |a| puts "#{a.ecf_id},#{a.user.trn},#{a.user.full_name},#{a.user.date_of_birth},#{a.user.national_insurance_number},#{a.user.email}" }
  end

  def csv
    CSV.generate(write_headers: true, headers: %w[application_ecf_id trn name dob nino email]) do |csv|
      query.each do |a|
        csv << [a.ecf_id, a.user.trn, a.user.full_name, a.user.date_of_birth, a.user.national_insurance_number, a.user.email]
      end
    end
  end

private

  def query
    Application.includes(:user).where(user: { trn_verified: false })
  end
end
