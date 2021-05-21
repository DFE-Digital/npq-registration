module Forms
  class ChooseYourProvider < Base
    OPTIONS = [
      OpenStruct.new(value: "NPQLT",
                     text: "NPQ Leading Teaching (NPQLT)",
                     link_errors: true),
      OpenStruct.new(value: "NPQLBC",
                     text: "NPQ Leading Behaviour and Culture (NPQLBC)",
                     link_errors: false),
      OpenStruct.new(value: "NPQLTD",
                     text: "NPQ Leading Teacher Development (NPQLTD)",
                     link_errors: false),
      OpenStruct.new(value: "NPQSL",
                     text: "NPQ for Senior Leadership (NPQSL)",
                     link_errors: false),
      OpenStruct.new(value: "NPQH",
                     text: "NPQ for Headship (NPQH)",
                     link_errors: false),
      OpenStruct.new(value: "NPQEL",
                     text: "NPQ for Executive Leadership (NPQEL)",
                     link_errors: false),
    ].freeze

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
