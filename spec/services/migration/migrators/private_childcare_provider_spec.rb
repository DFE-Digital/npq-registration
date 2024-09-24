require "rails_helper"

RSpec.describe Migration::Migrators::PrivateChildcareProvider do
  it_behaves_like "a migrator", :private_childcare_provider, [] do
    def create_ecf_resource
      create(:ecf_migration_npq_application)
    end

    def create_npq_resource(ecf_resource)
      create(:private_childcare_provider, provider_urn: ecf_resource.private_childcare_provider_urn)
    end

    def setup_failure_state
      # Empty urn
      create(:ecf_migration_npq_application, private_childcare_provider_urn: " ")
    end

    describe "#call" do
      it "does not change existing provider or create any more if already present" do
        provider = PrivateChildcareProvider.find_by(provider_urn: ecf_resource1.private_childcare_provider_urn)

        expect { instance.call }.not_to(change(PrivateChildcareProvider, :count))
        expect(provider.reload.disabled_at).to be_nil
      end

      it "does not create any more providers if already present and disabled" do
        PrivateChildcareProvider.find_by(provider_urn: ecf_resource1.private_childcare_provider_urn, disabled_at: 1.day.ago)

        expect { instance.call }.not_to(change(PrivateChildcareProvider, :count))
      end

      it "creates a disabled provider if it doesn't exist in NPQ reg" do
        ecf_provider = create(:ecf_migration_npq_application, private_childcare_provider_urn: "0123456")
        instance.call
        created_provider = PrivateChildcareProvider.including_disabled.find_by!(provider_urn: ecf_provider.private_childcare_provider_urn)
        expect(created_provider.disabled_at).to be_within(5.seconds).of(Time.zone.now)
      end
    end
  end
end
