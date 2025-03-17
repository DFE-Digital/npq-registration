require "rails_helper"

RSpec.describe DeliveryPartners::Query do
  let(:lead_provider_1) { LeadProvider.first }
  let(:lead_provider_2) { LeadProvider.last }
  let(:cohort_21) { create :cohort, start_year: 2021 }
  let(:cohort_22) { create :cohort, start_year: 2022 }
  let(:cohort_23) { create :cohort, start_year: 2023 }
  let(:sort) { nil }

  subject(:query) { described_class.new(lead_provider: lead_provider_1, sort: sort) }

  describe "#delivery_partners" do
    let!(:delivery_partner_1) { create :delivery_partner, name: "z", lead_providers: { cohort_21 => lead_provider_1 }, created_at: 2.minutes.ago }
    let!(:delivery_partner_2) { create :delivery_partner, name: "a", lead_providers: { cohort_21 => lead_provider_1, cohort_22 => lead_provider_1 }, created_at: 1.minute.ago }
    let!(:delivery_partner_other_lead_provider) { create :delivery_partner, lead_providers: { cohort_21 => lead_provider_2 }, created_at: 1.minute.ago }
    let!(:delivery_partner_an_hour_ago) { create :delivery_partner, name: "c", lead_providers: { cohort_23 => lead_provider_1 }, created_at: 1.hour.ago }

    it "returns delivery partners for the specified lead provider, ordered by name" do
      expect(query.delivery_partners).to eq([delivery_partner_2, delivery_partner_an_hour_ago, delivery_partner_1])
    end

    context "when sorting" do
      context "when sort is +created_at" do
        let(:sort) { "+created_at" }

        it "orders by created_at in ascending order" do
          expect(query.delivery_partners).to eq([delivery_partner_an_hour_ago, delivery_partner_1, delivery_partner_2])
        end
      end

      context "when sort is -created_at" do
        let(:sort) { "-created_at" }

        it "orders by created_at in descending order" do
          expect(query.delivery_partners).to eq([delivery_partner_2, delivery_partner_1, delivery_partner_an_hour_ago])
        end
      end
    end

    context "when filtering by lead_provider" do
      subject(:query) { described_class.new lead_provider: lead_provider_2 }

      it "returns delivery partners for the specified lead_provider" do
        expect(query.delivery_partners).to eq([delivery_partner_other_lead_provider])
      end
    end

    context "when filtering by cohort" do
      subject(:query) { described_class.new lead_provider: lead_provider_1, cohort_start_year: cohort_22.start_year }

      it "returns delivery partners for the specified cohort" do
        expect(query.delivery_partners).to eq([delivery_partner_2])
      end
    end
  end

  describe "#delivery_partner" do
    let!(:delivery_partner) do
      create(:delivery_partner,
             lead_providers: {
               cohort_21 => lead_provider_1,
               cohort_22 => lead_provider_1,
               cohort_23 => lead_provider_2,
             })
    end

    it "raises an error if no `id` or `ecf_id` is provided" do
      expect { query.delivery_partner }.to raise_error(ArgumentError).with_message("id or ecf_id needed")
    end

    it "returns the delivery_partner using the `id`" do
      expect(query.delivery_partner(id: delivery_partner.id)).to eq(delivery_partner)
    end

    it "returns the delivery_partner using the `ecf_id`" do
      expect(query.delivery_partner(ecf_id: delivery_partner.ecf_id)).to eq(delivery_partner)
    end

    it "raises an error if the delivery_partner does not exist" do
      expect { query.delivery_partner(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when a `lead_provider` is specified" do
      let!(:other_delivery_partner) { create(:delivery_partner, lead_providers: { cohort_23 => lead_provider_2 }) }

      subject(:query) { described_class.new(lead_provider: lead_provider_1) }

      it "returns the delivery_partner if the lead_provider is in the filtered query" do
        expect(query.delivery_partner(id: delivery_partner.id)).to eq(delivery_partner)
      end

      it "raises an error if the delivery_partner is not in the filtered query" do
        expect { query.delivery_partner(ecf_id: other_delivery_partner.ecf_id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect { query.delivery_partner(id: other_delivery_partner.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
