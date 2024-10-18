module NpqSeparation
  module Admin
    class OutcomesTableComponent < ViewComponent::Base
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
          "Sent to TRA API",
          "Recorded by API",
          "",
        ]
      end

      def rows
        outcomes.map do |outcome|
          [
            outcome.state.humanize,
            outcome.completion_date.to_fs(:govuk_short),
            outcome.created_at.to_date.to_fs(:govuk_short),
            outcome.sent_to_qualified_teachers_api_at&.to_date&.to_fs(:govuk_short) ||
              t("participant_outcomes.na"),
            recorded_by_tra_api(outcome),
            tra_api_resend_link(outcome),
          ]
        end
      end

      def recorded_by_tra_api(outcome)
        if outcome.qualified_teachers_api_request_successful.nil?
          if outcome.latest_for_declaration?
            tag.strong(t("participant_outcomes.pending"), class: "govuk-tag govuk-tag--blue")
          else
            tag.strong(t("participant_outcomes.na"), class: "govuk-tag govuk-tag--yellow")
          end
        else
          helpers.boolean_red_green_tag(outcome.qualified_teachers_api_request_successful)
        end
      end

      def tra_api_resend_link(outcome)
        return "" unless outcome.allow_resending_to_qualified_teachers_api?

        govuk_button_to(t("participant_outcomes.resend"),
                        resend_npq_separation_admin_participant_outcome_path(outcome),
                        class: "govuk-!-margin-bottom-0")
      end

      def caption_text
        title = t("participant_outcomes.declaration_outcomes")
        latest = outcomes.first

        return title if latest.nil?

        outcome_description = if latest.has_passed?
                                success_sent_state_message(latest)
                              elsif latest.has_failed?
                                failed_sent_state_message(latest)
                              else
                                latest.state.capitalize
                              end

        "#{title}: #{outcome_description}"
      end

      def success_sent_state_message(outcome)
        if outcome.not_sent?
          t("participant_outcomes.passed")
        elsif outcome.sent_and_recorded?
          t("participant_outcomes.passed_and_recorded")
        elsif outcome.sent_but_not_recorded?
          t("participant_outcomes.passed_but_not_recorded")
        else
          outcome.state.capitalize
        end
      end

      def failed_sent_state_message(outcome)
        if outcome.not_sent?
          t("participant_outcomes.failed")
        elsif outcome.sent_and_recorded?
          t("participant_outcomes.failed_and_recorded")
        elsif outcome.sent_but_not_recorded?
          t("participant_outcomes.failed_but_not_recorded")
        else
          outcome.state.capitalize
        end
      end
    end
  end
end
