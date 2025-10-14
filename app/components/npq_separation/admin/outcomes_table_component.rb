module NpqSeparation
  module Admin
    class OutcomesTableComponent < BaseComponent
      attr_reader :outcomes

      def initialize(outcomes)
        @outcomes = outcomes.sort_by(&:created_at).reverse
      end

      def call
        render GovukComponent::TableComponent.new(head:, rows:) do |table|
          table.with_caption(size: "s", text: caption_text, classes: "govuk-heading-s")
        end
      end

    private

      def head
        [
          "Outcome",
          "Completion date",
          "Submitted by provider",
        ]
      end

      def rows
        outcomes.map do |outcome|
          [
            outcome.state.humanize,
            outcome.completion_date.to_fs(:govuk_short),
            outcome.created_at.to_date.to_fs(:govuk_short),
          ]
        end
      end

      def caption_text
        title = "Declaration Outcomes"
        latest = outcomes.first

        if latest.nil?
          title
        else
          "#{title}: #{latest.state.capitalize}"
        end
      end
    end
  end
end
