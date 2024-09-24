require "rails_helper"

RSpec.describe Migration::Migrators::IttProvider do
  it_behaves_like "a migrator", :itt_provider, [] do
    def create_ecf_resource
      create(:ecf_migration_npq_application)
    end

    def create_npq_resource(ecf_resource)
      create(:itt_provider, legal_name: ecf_resource.itt_provider.upcase)
    end

    def setup_failure_state
      # Empty legal_name
      create(:ecf_migration_npq_application, itt_provider: " ")
    end

    describe "#call" do
      it "does not change existing provider or create any more if already present" do
        provider = IttProvider.find_by(legal_name: ecf_resource1.itt_provider)

        expect { instance.call }.not_to(change(IttProvider, :count))
        expect(provider.reload.disabled_at).to be_nil
      end

      it "does not create any more providers if already present and disabled" do
        IttProvider.find_by(legal_name: ecf_resource1.itt_provider, disabled_at: 1.day.ago)

        expect { instance.call }.not_to(change(IttProvider, :count))
      end

      it "creates a disabled provider if it doesn't exist in NPQ reg" do
        ecf_provider = create(:ecf_migration_npq_application, itt_provider: "other-provider")
        instance.call
        created_provider = IttProvider.including_disabled.find_by!(legal_name: ecf_provider.itt_provider, operating_name: ecf_provider.itt_provider)
        expect(created_provider.disabled_at).to be_within(5.seconds).of(Time.zone.now)
      end

      it "fallsback to operating_name if legal_name is not a match" do
        ecf_provider = create(:ecf_migration_npq_application)
        npq_provider = create(:itt_provider, legal_name: "not-a-match", operating_name: ecf_provider.itt_provider)

        expect { instance.call }.not_to(change(IttProvider, :count))
        expect(npq_provider.reload.disabled_at).to be_nil
      end
    end
  end
end
