module Services
  class RevalidateApplications
    def initialize(application_ecf_ids:)
      @application_ecf_ids = application_ecf_ids
    end

    def call
      applications.each do |application|
        record = Services::ParticipantValidator.new(
          trn: application.user.trn,
          full_name: application.user.full_name,
          date_of_birth: application.user.date_of_birth,
          national_insurance_number: application.user.national_insurance_number,
        ).call

        next unless record

        application.user.update!(
          trn: record.trn,
          trn_verified: true,
          trn_auto_verified: true,
          active_alert: record.active_alert,
        )
      end

      puts "=== START CSV"
      puts "application_ecf_id,validated_trn,active_alert"
      Application
        .includes(:user)
        .where(ecf_id: application_ecf_ids)
        .where(user: { trn_verified: true })
        .each { |a| puts "#{a.ecf_id},#{a.user.trn},#{a.user.active_alert}" }
    end

  private

    attr_reader :application_ecf_ids

    def applications
      @applications ||= Application.includes(:user).where(ecf_id: application_ecf_ids)
    end
  end
end
