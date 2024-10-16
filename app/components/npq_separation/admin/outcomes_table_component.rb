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
          "Recorded by API",
          "",
        ]
      end

      def rows
        outcomes.sort_by(&:created_at).reverse.map do |outcome|
          [
            outcome.state.humanize,
            outcome.completion_date.to_fs(:govuk_short),
            outcome.created_at.to_date.to_fs(:govuk_short),
            outcome.sent_to_qualified_teachers_api_at&.to_date&.to_fs(:govuk_short) || "No",
            recorded_by_tra_api(outcome),
            tra_api_resend_link(outcome),
          ]
        end
      end

      def recorded_by_tra_api(outcome)
        if outcome.qualified_teachers_api_request_successful.nil?
          outcome.latest_for_declaration? ? "Pending" : "N/A"
        else
          helpers.boolean_red_green_tag(outcome.qualified_teachers_api_request_successful)
        end
      end

      def tra_api_resend_link(outcome)
        return "" unless outcome.allow_resending_to_qualified_teachers_api?

        govuk_link_to("Resend", resend_npq_separation_admin_participant_outcome_path(outcome))
      end
    end
  end
end
