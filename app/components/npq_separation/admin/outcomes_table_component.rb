module NpqSeparation
  module Admin
    class OutcomesTableComponent < ViewComponent::Base
      attr_reader :outcomes

      def initialize(outcomes)
        @outcomes = outcomes
      end

      def call
        render GovukComponent::TableComponent.new(head:, rows:)
      end

    private

      def head
        [
          "Outcome",
          "Completion date",
          "Submitted by provider",
          "Sent to TRA API",
          "Recorded by TRA API",
        ]
      end

      def rows
        outcomes.sort_by(&:created_at).reverse.map do |outcome|
          [
            outcome.state.humanize,
            outcome.completion_date.to_fs(:govuk_short),
            outcome.created_at.to_date.to_fs(:govuk),
            outcome.sent_to_qualified_teachers_api_at.try(:to_fs, :govuk_short).presence || "N/A",
            recorded_by_tra_api(outcome),
          ]
        end
      end

      def recorded_by_tra_api(outcome)
        if outcome.qualified_teachers_api_request_successful.nil?
          if outcome.latest_for_declaration?
            tag.strong("Pending", class: "govuk-tag govuk-tag--blue")
          else
            tag.strong("N/A", class: "govuk-tag govuk-tag--yellow")
          end
        else
          helpers.boolean_red_green_tag(outcome.qualified_teachers_api_request_successful)
        end
      end
    end
  end
end
