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
      :choose_your_provider
    end

    def previous_step
      :qualified_teacher_check
    end

    def options
      OPTIONS
    end
  end
end
