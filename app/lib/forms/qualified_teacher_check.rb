module Forms
  class QualifiedTeacherCheck < Base
    include ActiveRecord::AttributeAssignment

    attr_accessor :trn, :first_name, :last_name

    attr_reader :date_of_birth

    def date_of_birth=(value)
      @date_of_birth = ActiveRecord::Type::Date.new.cast(value)
    end

    validates :trn, presence: true, length: { in: 7..10 }
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :date_of_birth, presence: true

    def self.permitted_params
      %i[
        trn
        first_name
        last_name
        date_of_birth
      ]
    end

    def next_step
      :choose_your_npq
    end

    def previous_step
      :confirm_email
    end
  end
end
