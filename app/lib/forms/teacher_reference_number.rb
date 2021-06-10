module Forms
  class TeacherReferenceNumber < Base
    VALID_TRN_KNOWLEDGE_OPTIONS = %w[yes no-dont-know no-dont-have].freeze

    attr_accessor :trn_knowledge

    validates :trn_knowledge, presence: true, inclusion: { in: VALID_TRN_KNOWLEDGE_OPTIONS }

    def self.permitted_params
      %i[
        trn_knowledge
      ]
    end

    def next_step
      case trn_knowledge
      when "yes"
        :name_changes
      when "no-dont-know"
        :dont_know_teacher_reference_number
      when "no-dont-have"
        :dont_have_teacher_reference_number
      end
    end

    def previous_step
      :share_provider
    end
  end
end
