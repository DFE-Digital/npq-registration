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
      end

      def dependencies
        %i[statement declaration]
      end
    end

    def call
      migrate(self.class.ecf_statement_items) do |ecf_statement_item|
        statement = ::Statement.find_or_initialize_by(ecf_id: ecf_statement_item.statement_id)
        declaration_id = ::Declaration.select(:id).find_by!(ecf_id: ecf_statement_item.participant_declaration_id).id
        statement_item = ::StatementItem.find_or_initialize_by(
          statement:,
          declaration_id:,
          state: ecf_statement_item.state,
        )

        statement_item.update!(ecf_statement_item.attributes.slice(:created_at, :updated_at))
      end
    end
  end
end
