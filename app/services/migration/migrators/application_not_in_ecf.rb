module Migration::Migrators
  class ApplicationNotInEcf < Base
    def call
      migrate(applications, :application_not_in_ecf) do |application|
        Migration::Ecf::NpqApplication.joins(:participant_identity).find_by!(id: application.ecf_id)
      end
    end

  private

    def applications
      @applications ||= ::Application.joins(:user).all
    end
  end
end
