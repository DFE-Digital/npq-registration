require "rails_helper"

RSpec.describe Migration::Migrators::Declaration do
  it_behaves_like "a migrator", :declaration, %i[cohort application lead_provider course user] do
    def create_ecf_resource
      create(:ecf_migration_participant_declaration, :ineligible)
    end

    def create_npq_resource(ecf_resource)
      lead_provider = create(:lead_provider, ecf_id: ecf_resource.cpd_lead_provider.npq_lead_provider.id)
      cohort = create(:cohort, start_year: ecf_resource.cohort.start_year)
      course = create(:course, identifier: ecf_resource.course_identifier)
      user = create(:user, ecf_id: ecf_resource.user.id)
      application = create(:application, :accepted, course:, user:)
      create(:declaration, ecf_id: ecf_resource.id, cohort:, lead_provider:, application:)
    end

    def setup_failure_state
      # Declaration with no associated application
      create(:ecf_migration_participant_declaration)
    end

    describe "#call" do
      it "sets the created Declaration attributes correctly" do
        instance.call
        declaration = Declaration.find_by(ecf_id: ecf_resource1.id)
        expect(declaration).to have_attributes(ecf_resource1.attributes.slice(:created_at, :udpated_at, :declaration_date, :declaration_type, :state))
        expect(declaration.state_reason).to eq(ecf_resource1.declaration_states.last.state_reason)
        expect(declaration.cohort.start_year).to eq(ecf_resource1.cohort.start_year)
        expect(declaration.lead_provider.ecf_id).to eq(ecf_resource1.cpd_lead_provider.npq_lead_provider.id)
        expect(declaration.application.course.identifier).to eq(ecf_resource1.course_identifier)
        expect(declaration.application.user.ecf_id).to eq(ecf_resource1.user.id)
      end
    end
  end
end
