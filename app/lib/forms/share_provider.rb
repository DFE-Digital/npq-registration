module Forms
  class ShareProvider
    include ActiveModel::Model

    attr_accessor :can_share_choices

    validates :can_share_choices, acceptance: true

    def self.permitted_params
      %i[
        can_share_choices
      ]
    end

    def next_step
      :teacher_reference_number
    end
  end
end
