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

      def records_per_worker
        (super / 2.0).ceil
      end
    end

    def call
      migrate(self.class.ecf_statement_items) do |ecf_statement_items|
        statement_items_to_update = []

        ecf_statement_items.each do |ecf_statement_item|
          statement_id = self.class.find_statement_id!(ecf_id: ecf_statement_item.statement_id)
          declaration_id = self.class.find_declaration_id!(ecf_id: ecf_statement_item.participant_declaration_id)
          statement_item = ::StatementItem.new(ecf_id: ecf_statement_item.id, created_at: Time.zone.now, updated_at: Time.zone.now)

          statement_item.assign_attributes(
            ecf_statement_item.attributes.slice(:state, :created_at, :updated_at).merge(statement_id:, declaration_id:),
          )

          unless statement_item.valid?
            raise ActiveRecord::ActiveRecordError("Validation failed: #{statement_item.errors.full_messages.join(', ')}")
          end

          statement_items_to_update << statement_item

          increment_processed_count
        rescue ActiveRecord::ActiveRecordError => e
          increment_failure_count(ecf_statement_item, e)
        end

        # Super hacky just to test performance
        attrs = %w[ecf_id state created_at updated_at statement_id declaration_id]
        records = statement_items_to_update.map(&:attributes).map { |attributes| attributes.slice(*attrs) }.map(&:symbolize_keys)
        ::StatementItem.upsert_all(records, unique_by: :ecf_id)
      end
    end
  end
end
