module Forms
  class TeacherReferenceNumber
    include ActiveModel::Model

    attr_accessor :trn_knowledge

    validates :trn_knowledge, presence: true

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
      :share_provider
    end
  end
end
