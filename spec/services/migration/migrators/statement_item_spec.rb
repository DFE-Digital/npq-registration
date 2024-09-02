require "rails_helper"

RSpec.describe Migration::Migrators::StatementItem do
  it_behaves_like "a migrator", :statement_item, %i[statement declaration] do
    def create_ecf_resource
      create(:ecf_migration_statement_line_item)
    end

    def create_npq_resource(ecf_resource)
      statement = create(:statement, ecf_id: ecf_resource.statement_id)
      declaration = create(:declaration, ecf_id: ecf_resource.participant_declaration_id)
      create(:statement_item, declaration:, statement:, state: ecf_resource.state)
    end

    def setup_failure_state
      # Declaration does not exist in NPQ reg
      create(:ecf_migration_statement_line_item)
    end

    describe "#call" do
      it "creates the StatementItems and sets attributes correctly" do
        instance.call

        statement_item = StatementItem.includes(:statement, :declaration).find_by(statement: { ecf_id: ecf_resource1.statement_id })
        expect(statement_item).to have_attributes(ecf_resource1.attributes.slice(:state, :created_at, :updated_at))
        expect(statement_item.declaration.ecf_id).to eq(ecf_resource1.participant_declaration_id)
        expect(statement_item.statement.ecf_id).to eq(ecf_resource1.statement_id)
      end
    end
  end
end
