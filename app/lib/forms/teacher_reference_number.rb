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
        :contact_details
      when "no-dont-know"
        :dont_know_teacher_reference_number
      when "no-dont-have"
        :dont_have_teacher_reference_number
      end
    end

    def previous_step
      :work_in_school
    end

    def title
      if wizard.query_store.inside_catchment? && wizard.query_store.works_in_school?
        "You need your teacher reference number to register for an NPQ"
      else
        "You’ll need a teacher reference number to register for an NPQ"
      end
    end
  end
end
