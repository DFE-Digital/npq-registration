module Forms
  class HeadteacherDuration < Base
    VALID_HEADTEACHER_STATUS_OPTIONS = %w[yes_in_first_two_years yes_over_two_years yes_when_course_starts no].freeze

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
        OpenStruct.new(value: "yes_in_first_two_years",
                       text: "Yes, I have been a headteacher less than 24 months",
                       link_errors: true),
        OpenStruct.new(value: "yes_over_two_years",
                       text: "No, I have been a headteacher for more than 24 months",
                       link_errors: false),
        OpenStruct.new(value: "yes_when_course_starts",
                       text: "No, I will be a headteacher when the course starts",
                       link_errors: false),
        OpenStruct.new(value: "no",
                       text: "No, I am not a headteacher",
                       link_errors: false),
      ]
    end
  end
end
