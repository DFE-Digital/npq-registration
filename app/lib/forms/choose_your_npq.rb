module Forms
  class ChooseYourNpq < Base
    attr_accessor :npq

    validates :npq, presence: true

    def self.permitted_params
      %i[
        npq
      ]
    end

    def next_step
    end

    def previous_step
      :qualified_teacher_check
    end
  end
end
