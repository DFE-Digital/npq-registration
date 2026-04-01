module Registration
  class CheckUserAgainstDqt
    def initialize(repository:, step:)
      @repository = repository
      @step = step
    end

    def execute
      fetch_dqt_record!
      update_user_with_dqt_result!

      { success: true }
    end

  private

    def current_user
      @step.wizard.state_store.current_user
    end

    def update_user_with_dqt_result!
      if @dqt_record.present?
        update_user_with_dqt_record!
      else
        update_user_without_dqt_record!
      end
    end

    def fetch_dqt_record!
      @dqt_record = ParticipantValidator.new(
        trn: @step.trn_digits_only,
        full_name: @step.full_name,
        date_of_birth: @step.date_of_birth,
        national_insurance_number: @step.national_insurance_number,
      ).call
    end

    def update_user_with_dqt_record!
      current_user.update!(
        trn_verified: true,
        trn: @dqt_record.trn.presence&.rjust(7, "0"),
        trn_auto_verified: true,
        trn_lookup_status: "Found",
        active_alert: @dqt_record.active_alert,
        full_name: @step.full_name,
        date_of_birth: @step.date_of_birth,
        national_insurance_number: nil,
      )
    end

    def update_user_without_dqt_record!
      current_user.update!(
        trn_verified: false,
        trn: @step.trn.presence&.rjust(7, "0"),
        trn_auto_verified: false,
        trn_lookup_status: "Failed",
        active_alert: nil,
        full_name: @step.full_name,
        date_of_birth: @step.date_of_birth,
        national_insurance_number: @step.national_insurance_number,
      )
    end
  end
end
