module NpqSeparation
  module Admin
    class OutcomesTableComponent < ViewComponent::Base
      attr_reader :outcomes

      def initialize(outcomes)
        @outcomes = outcomes
      end

      def call
        if outcomes.none?
          tag.p "No outcomes recorded.", class: "govuk-body"
        else
          render(GovukComponent::TableComponent.new(head:, rows:))
        end
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
            outcome.sent_to_qualified_teachers_api_at.try(:to_fs, :govuk_short).presence || "No",
            helpers.boolean_red_green_nil_tag(outcome.qualified_teachers_api_request_successful),
          ]
        end
      end
    end
  end
end
