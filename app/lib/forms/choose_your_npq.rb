module Forms
  class ChooseYourNpq < Base
    OPTIONS = [
      "NPQ Leading Teaching (NPQLT)",
      "NPQ Leading Behaviour and Culture (NPQLBC)",
      "NPQ Leading Teacher Development (NPQLTD)",
      "NPQ for Senior Leadership (NPQSL)",
      "NPQ for Headship (NPQH)",
      "NPQ for Executive Leadership (NPQEL)",
    ].each_with_index.map { |option, index|
      OpenStruct.new(value: option,
                     text: option,
                     link_errors: index.zero?)
    }.freeze

    attr_accessor :npq

    validates :npq, presence: true

    def self.permitted_params
      %i[
        npq
      ]
    end

    def next_step
      if studying_for_headship?
        :headteacher_duration
      else
        :choose_your_provider
      end
    end

    def previous_step
      :qualified_teacher_check
    end

    def studying_for_headship?
      npq == "NPQ for Headship (NPQH)"
    end

    def options
      OPTIONS
    end
  end
end
