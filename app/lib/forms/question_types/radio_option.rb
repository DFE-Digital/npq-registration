module Forms
  module QuestionTypes
    class RadioOption
      attr_reader :value,
                  :link_errors,
                  :divider,
                  :revealed_question

      def initialize(value:, link_errors: false, divider: false, revealed_question: nil)
        @value = value
        @link_errors = link_errors
        @divider = divider
        @revealed_question = revealed_question
      end
    end
  end
end
