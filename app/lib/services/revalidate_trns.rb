module Services
  class RevalidateTrns
    attr_reader :application_ids

    def initialize(application_ids:)
      @application_ids = application_ids
    end

    def call
      applications.each do |app|
        r = Services::ParticipantValidator.new(
          trn: app.user.trn,
          full_name: app.user.full_name,
          date_of_birth: app.user.date_of_birth,
          national_insurance_number: app.user.national_insurance_number,
        ).call

        if r.nil?
          puts "no record found for application: #{app.ecf_id} with trn: #{app.user.trn}"
          next
        end

        puts "updating application: #{app.ecf_id} with trn: #{r.trn}..."

        app.user.update!(trn: r.trn, trn_verified: true, active_alert: r.active_alert)
      end

      output_csv
    end

  private

    def applications
      @applications ||= Application.includes(:user).where(ecf_id: application_ids)
    end

    def output_csv
      puts "application_ecf_id,validated_trn,active_alert"
      Application.includes(:user).where(ecf_id: application_ids).where(user: { trn_verified: true }).each do |app|
        puts "#{app.ecf_id},#{app.user.trn},#{app.user.active_alert}"
      end
    end
  end
end

application_ids = %w[]

svc = Services::RevalidateTrns.new(application_ids: application_ids)
svc.call
