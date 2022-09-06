module Forms
  class NpqhStatus < Base
    VALID_NPQH_STATUS_OPTIONS = %w[completed_npqh studying_npqh will_start_npqh none].freeze

    include Helpers::Institution

    attr_accessor :npqh_status

    validates :npqh_status, presence: true, inclusion: { in: VALID_NPQH_STATUS_OPTIONS }

    def self.permitted_params
      %i[
        npqh_status
      ]
    end

    def next_step
      if npqh_status == "none"
        :aso_unavailable
      else
        :aso_headteacher
      end
    end

    def previous_step
      :about_ehco
    end

    def options
      [
        build_option_struct(value: "completed_npqh", link_errors: true),
        build_option_struct(value: "studying_npqh"),
        build_option_struct(value: "will_start_npqh"),
        build_option_struct(value: "none", divider: true),
      ]
    end
  end
end
