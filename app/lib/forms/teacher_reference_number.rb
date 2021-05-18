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
  end
end
