require "rails_helper"

RSpec.describe Migration::Migrators::DeclarationSupersededBy do
  it_behaves_like "a migrator", :declaration_superseded_by, %i[declaration] do
    def create_ecf_resource
      create(:ecf_migration_participant_declaration, :ineligible).tap do |declaration|
        # We use the same declaration here to make the test setup easier.
        declaration.update!(superseded_by_id: declaration.id)
      end
    end

    def create_npq_resource(ecf_resource)
      create(:declaration, :ineligible, ecf_id: ecf_resource.id)
    end

    def setup_failure_state
      # Declaration in ECF where we can't find the superseded by declaration in NPQ reg.
      other_declaration = create(:ecf_migration_participant_declaration)
      create(:ecf_migration_participant_declaration, superseded_by_id: other_declaration.id)
    end

    describe "#call" do
      it "sets the superseded_by_id on the declarations" do
        instance.call
        declaration = Declaration.find_by(ecf_id: ecf_resource1.id)
        superseded_by_declaration = Declaration.find_by(ecf_id: ecf_resource1.superseded_by_id)
        expect(declaration.superseded_by_id).to eq(superseded_by_declaration.id)
      end

      it "does not update the timestamp on the declarations" do
        declaration = Declaration.find_by(ecf_id: ecf_resource1.id)
        declaration_updated_at = declaration.updated_at

        instance.call

        expect(declaration_updated_at).to eq(declaration.reload.updated_at)
      end
    end
  end
end
