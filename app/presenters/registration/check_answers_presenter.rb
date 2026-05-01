module Registration
  class CheckAnswersPresenter
    Answer = Struct.new(:key, :value, :change_step)

    delegate_missing_to :@store

    attr_reader :store

    def initialize(store)
      @store = store
    end

    def answers
      array = []

      array << Answer.new("Course start", course_start, :course_start_date)

      array
    end

  private

    def course_start
      "In autumn 2025" if course_start_date
    end

    def t(key)
      I18n.t(store[key], scope: "helpers.label.registration_wizard.#{key}_options")
    end
  end
end
