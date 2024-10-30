require "rails_helper"

RSpec.describe Migration::Migrators::Declaration do
  it_behaves_like "a migrator", :declaration, %i[cohort application lead_provider course user] do
    let(:records_per_worker_divider) { 2 }

    def create_ecf_resource
      travel_to(rand(100).hours.ago) do
        create(:ecf_migration_participant_declaration, :ineligible)
      end
    end

    def create_npq_resource(ecf_resource)
      lead_provider = create(:lead_provider, ecf_id: ecf_resource.cpd_lead_provider.npq_lead_provider.id)
      cohort = create(:cohort, ecf_id: ecf_resource.cohort_id, start_year: ecf_resource.cohort.start_year)
      course = create(:course, identifier: ecf_resource.course_identifier.upcase)
      user = create(:user, ecf_id: ecf_resource.user.id)
      application = create(:application, :accepted, course:, user:, ecf_id: ecf_resource.participant_profile.npq_application.id)
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
        expect(declaration).to have_attributes(ecf_resource1.attributes.slice("declaration_type", "state"))
        expect(declaration.state_reason).to eq(ecf_resource1.declaration_states.last.state_reason)
        expect(declaration.cohort.start_year).to eq(ecf_resource1.cohort.start_year)
        expect(declaration.lead_provider.ecf_id).to eq(ecf_resource1.cpd_lead_provider.npq_lead_provider.id)
        expect(declaration.application.ecf_id).to eq(ecf_resource1.participant_profile.npq_application.id)
        expect(declaration.created_at.to_s).to eq(ecf_resource1.created_at.to_s)
        expect(declaration.updated_at.to_s).to eq(ecf_resource1.updated_at.to_s)
        expect(declaration.declaration_date.to_s).to eq(ecf_resource1.declaration_date.to_s)
      end

      context "when declaration date is before the schedule start" do
        before do
          declaration = Declaration.find_by(ecf_id: ecf_resource1.id)
          ecf_resource1.update!(declaration_date: declaration.application.schedule.applies_from.prev_week)
        end

        it "does not record a failure" do
          instance.call

          expect(failure_manager).not_to have_received(:record_failure)
        end
      end
    end
  end
end
