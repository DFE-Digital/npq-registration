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
      migrate(self.class.ecf_declarations) do |ecf_declaration|
        declaration = find_declaration!(ecf_id: ecf_declaration.id)

        declaration.update!(
          superseded_by: find_declaration!(ecf_id: ecf_declaration.superseded_by_id),
        )
      end
    end
  end
end
