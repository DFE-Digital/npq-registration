module Forms
  class TeacherReferenceNumber < Base
    VALID_TRN_KNOWLEDGE_OPTIONS = %w[yes no-dont-have].freeze

    attr_accessor :trn_knowledge

    validates :trn_knowledge, presence: true, inclusion: { in: VALID_TRN_KNOWLEDGE_OPTIONS }

    def self.permitted_params
      %i[
        trn_knowledge
      ]
    end

    # Required since this is the first question
    # If it wasn't overridden it would check if any previous questions were answered
    # and since there aren't any it would assume the user was trying to skip questions
    # and redirect them to the start page
    def requirements_met?
      true
    end

    def next_step
      case trn_knowledge
      when "yes"
        :qualified_teacher_check
      when "no-dont-have"
        :dont_have_teacher_reference_number
      end
    end

    def previous_step
      :start
    end

    def questions
      [
        Forms::QuestionTypes::RadioButtonGroup.new(
          name: :trn_knowledge,
          options:,
          style_options: { legend: { size: "m", tag: "h1" } },
        ),
      ]
    end

    def options
      [
        build_option_struct(value: :yes, link_errors: true),
        build_option_struct(value: :"no-dont-have"),
      ]
    end
  end
end
