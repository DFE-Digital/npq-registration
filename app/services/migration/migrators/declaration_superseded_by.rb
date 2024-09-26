module Migration::Migrators
  class DeclarationSupersededBy < Base
    class << self
      def record_count
        ecf_declarations.count
      end

      def model
        :declaration_superseded_by
      end

      def ecf_declarations
        Declaration.ecf_declarations.where.not(superseded_by_id: nil)
      end

      def dependencies
        %i[declaration]
      end
    end

    def call
      migrate(self.class.ecf_declarations) do |ecf_declarations|
        ecf_declarations.each do |ecf_declaration|
          declaration = ::Declaration.find_by!(ecf_id: ecf_declaration.id)

          declaration.update!(
            superseded_by_id: self.class.find_declaration_id!(ecf_id: ecf_declaration.superseded_by_id),
          )
          increment_processed_count
        rescue ActiveRecord::ActiveRecordError => e
          increment_failure_count(ecf_declaration, e)
        end
      end
    end
  end
end
