require "rails_helper"

RSpec.describe Cohorts::CopyDeliveryPartners do
  describe "#copy" do
    let!(:previous_cohort) { create(:cohort, start_year: 2024) }
    let(:cohort) { create(:cohort, start_year: 2025) }
    let(:service) { described_class.new(cohort) }

    let(:lead_provider_1) { create(:lead_provider) }
    let(:lead_provider_2) { create(:lead_provider) }
    let(:delivery_partner_1) { create(:delivery_partner) }
    let(:delivery_partner_2) { create(:delivery_partner) }

    context "when the previous cohort has delivery partners" do
      let(:partnerships) { cohort.delivery_partnerships }

      before do
        create(:delivery_partnership,
               cohort: previous_cohort,
               lead_provider: lead_provider_1,
               delivery_partner: delivery_partner_1)
        create(:delivery_partnership,
               cohort: previous_cohort,
               lead_provider: lead_provider_2,
               delivery_partner: delivery_partner_2)
      end

      it "copies delivery partners from the previous cohort" do
        expect {
          service.copy
        }.to change { cohort.delivery_partnerships.count }.from(0).to(2)

        expect(partnerships.pluck(:lead_provider_id)).to contain_exactly(lead_provider_1.id, lead_provider_2.id)
        expect(partnerships.pluck(:delivery_partner_id)).to contain_exactly(delivery_partner_1.id, delivery_partner_2.id)
      end
    end

    shared_examples "does not copy delivery partners" do
      it "does not create any delivery partnerships" do
        expect {
          service.copy
        }.not_to(change { cohort.delivery_partnerships.count })
      end
    end

    context "when the previous cohort has no delivery partners" do
      it_behaves_like "does not copy delivery partners"
    end

    context "when there is no previous cohort" do
      before { previous_cohort.destroy }

      it_behaves_like "does not copy delivery partners"
    end
  end
end
