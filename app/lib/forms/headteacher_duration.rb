module Forms
  class HeadteacherDuration < Base
    VALID_HEADTEACHER_STATUS_OPTIONS = %w[yes no].freeze

    attr_accessor :headteacher_status

    validates :headteacher_status, presence: true, inclusion: { in: VALID_HEADTEACHER_STATUS_OPTIONS }

    def self.permitted_params
      %i[
        headteacher_status
      ]
    end

    def next_step
      if changing_answer?
        :check_answers
      else
        :choose_your_provider
      end
    end

    def previous_step
      :choose_your_npq
    end

    def options
      [
        OpenStruct.new(value: "yes",
                       text: "Yes, I have been a headteacher for two years or more",
                       link_errors: true),
        OpenStruct.new(value: "no",
                       text: "No, I’m not a headteacher or have been a headteacher for less than two years",
                       link_errors: false),
      ]
    end
  end
end
