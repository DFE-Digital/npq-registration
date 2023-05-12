module Forms
  module QuestionTypes
    class RadioOption
      attr_reader :value, :link_errors, :divider, :revealed_question, :label

      def initialize(value:, link_errors: false, divider: false, revealed_question: nil, label: {})
        @value = value
        @link_errors = link_errors
        @divider = divider
        @revealed_question = revealed_question
        @label = label
      end
    end
  end
end
