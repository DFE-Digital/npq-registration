module Forms
  class ShareProvider < Base
    attr_accessor :can_share_choices

    validates :can_share_choices, acceptance: true

    def self.permitted_params
      %i[
        can_share_choices
      ]
    end

    def next_step
      :check_answers
    end

    def previous_step
      :choose_your_provider
    end
  end
end
