module Questionnaires
  class Start < Base
    attribute :started, :boolean

    validates :current_user, presence: true, if: :dfe_wizard?
    validates :started, presence: true, acceptance: true, if: :dfe_wizard?

    def self.permitted_params = %i[start]

    def requirements_met?
      true
    end

    def next_step
      :course_start_date
    end

  private

    def current_user
      wizard.state_store.current_user
    end
  end
end
