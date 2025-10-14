module NpqSeparation
  module Admin
    class OutcomesTableComponent < BaseComponent
      attr_reader :outcomes

      def initialize(outcomes)
        @outcomes = outcomes.sort_by(&:completion_date).reverse
      end

      def call
        render GovukComponent::TableComponent.new(head:, rows:)
      end

    private

      def head
        [
          "Outcome",
          helpers.safe_join([
            "Course started".html_safe,
            helpers.tag.div("The declaration date on the started declaration", class: "govuk-hint govuk-!-margin-top-1"),
          ]),
          "Course completed",
          "Submitted by provider",
        ]
      end

      def rows
        outcomes.map do |outcome|
          [
            outcome_status_tag(outcome.state),
            course_started_date(outcome.declaration)&.to_date&.to_fs(:govuk_short),
            outcome.completion_date.to_fs(:govuk_short),
            outcome.created_at.to_date.to_fs(:govuk_short),
          ]
        end
      end

      def outcome_status_tag(state)
        case state
        when "passed"
          helpers.govuk_tag(text: "Passed", colour: "green")
        when "failed"
          helpers.govuk_tag(text: "Failed", colour: "red")
        else
          helpers.govuk_tag(text: state.humanize, colour: "grey")
        end
      end

      def course_started_date(declaration)
        declaration.application.declarations.find_by(declaration_type: "started").declaration_date
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
