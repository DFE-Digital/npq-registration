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
      options_array.each_with_index.map do |option, index|
        OpenStruct.new(value: option[:value],
                       text: option[:text],
                       link_errors: index.zero?)
      end
    end

  private

    def options_array
      [
        {
          text: "I have completed an NPQH",
          value: "completed_npqh",
        },
        {
          text: "I am still studying for an NPQH",
          value: "studying_npqh",
        },
        {
          text: "I am about to start an NPQH",
          value: "will_start_npqh",
        },
        {
          text: "None of the above",
          value: "none",
        },
      ]
    end
  end
end
