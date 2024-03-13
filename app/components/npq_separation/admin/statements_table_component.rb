module NpqSeparation
  module Admin
    class StatementsTableComponent < ViewComponent::Base
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
          "ID",
          ("Lead provider" if show_lead_provider),
          "Cohort",
          "Status",
          govuk_visually_hidden("Action"),
        ].compact
      end

      def rows
        statements.map do |statement|
          [
            id_link(statement),
            lead_provider_link(statement.lead_provider),
            cohort_link(statement),
            statement_tag(statement),
            view_link(statement),
          ].compact
        end
      end

      def id_link(statement)
        govuk_link_to(statement.id.to_s, npq_separation_admin_finance_statement_path(statement), **metadata_link_arguments)
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
        govuk_tag(text: statement.state.capitalize)
      end

      def metadata_link_arguments
        { text_colour: true, no_underline: true }
      end
    end
  end
end
