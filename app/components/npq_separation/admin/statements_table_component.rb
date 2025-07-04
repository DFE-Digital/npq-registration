module NpqSeparation
  module Admin
    class StatementsTableComponent < ViewComponent::Base
      STATE_COLOURS = {
        open: "govuk-tag--grey",
        payable: "govuk-tag--red",
        paid: "govuk-tag--green",
      }.freeze

      attr_reader :statements, :show_lead_provider, :caption

      def initialize(statements, show_lead_provider: true, caption: nil)
        @statements = statements
        @caption = caption
        @show_lead_provider = show_lead_provider
      end

      def call
        render(GovukComponent::TableComponent.new(caption:, head:, rows:))
      end

    private

      def head
        [
          ("Course provider" if show_lead_provider),
          "Cohort",
          "Statement date",
          "Status",
          "Actions",
        ].compact
      end

      def rows
        statements.map do |statement|
          [
            lead_provider_link(statement.lead_provider),
            cohort_link(statement),
            helpers.statement_name(statement),
            statement_tag(statement),
            view_link(statement),
          ].compact
        end
      end

      def view_link(statement)
        govuk_link_to(
          "View",
          npq_separation_admin_finance_statement_path(statement),
          no_visited_state: true,
          visually_hidden_suffix: "statement #{statement.id}",
        )
      end

      def lead_provider_link(lead_provider)
        return unless show_lead_provider

        govuk_link_to(lead_provider.name, npq_separation_admin_lead_provider_path(lead_provider), **metadata_link_arguments)
      end

      def cohort_link(statement)
        text = helpers.format_cohort(statement.cohort)

        govuk_link_to(text, "#", **metadata_link_arguments)
      end

      def statement_tag(statement)
        govuk_tag(
          text: statement.state.capitalize,
          classes: STATE_COLOURS[statement.state.to_sym],
        )
      end

      def metadata_link_arguments
        { text_colour: true, no_underline: true }
      end
    end
  end
end
