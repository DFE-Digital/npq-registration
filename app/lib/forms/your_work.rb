module Forms
  class YourWork < Base
    attr_accessor :employer_name, :employment_role

    validates :employer_name, :employment_role, presence: true

    def self.permitted_params
      %i[employer_name employment_role]
    end

    def next_step
      :funding_your_npq
    end

    def previous_step
      :choose_your_npq
    end
  end
end
