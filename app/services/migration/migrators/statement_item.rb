module Migration::Migrators
  class StatementItem < Base
    class << self
      def record_count
        ecf_statement_items.count
      end

      def model
        :statement_item
      end

      def ecf_statement_items
        Migration::Ecf::Finance::StatementLineItem
          .joins(:participant_declaration)
          .where(participant_declaration: { type: "ParticipantDeclaration::NPQ" })
      end

      def dependencies
        %i[statement declaration]
      end
    end

    def call
      migrate(self.class.ecf_statement_items) do |ecf_statement_item|
        statement_id = find_statement_id!(ecf_id: ecf_statement_item.statement_id)
        declaration_id = find_declaration_id!(ecf_id: ecf_statement_item.participant_declaration_id)
        statement_item = ::StatementItem.find_or_initialize_by(
          statement_id:,
          declaration_id:,
          state: ecf_statement_item.state,
        )

        statement_item.update!(ecf_statement_item.attributes.slice(:created_at, :updated_at))
      end
    end
  end
end
