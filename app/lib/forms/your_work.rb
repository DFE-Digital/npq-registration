module Forms
  class YourWork < Base
    attr_accessor :employer_name, :employment_role

    validates :employer_name, :employment_role, presence: true

    def self.permitted_params
      %i[employer_name employment_role]
    end

    def next_step
      :share_provider
    end

    def previous_step
      :choose_your_provider
    end
  end
end
