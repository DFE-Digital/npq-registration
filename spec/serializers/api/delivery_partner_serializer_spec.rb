require "rails_helper"

RSpec.describe API::DeliveryPartnerSerializer, type: :serializer do
  let(:current_lead_provider) { LeadProvider.first }
  let(:other_lead_provider) { LeadProvider.last }
  let(:delivery_partner) do
    create(:delivery_partner,
           lead_providers: {
             cohort_21 => current_lead_provider,
             cohort_22 => current_lead_provider,
             cohort_23 => other_lead_provider,
           })
  end
  let(:cohort_21) { create :cohort, start_year: 2021 }
  let(:cohort_22) { create :cohort, start_year: 2022 }
  let(:cohort_23) { create :cohort, start_year: 2023 }

  subject(:response) { JSON.parse(described_class.render(delivery_partner)) }

  describe "core attributes" do
    it "serializes the `id`" do
      expect(response["id"]).to eq(delivery_partner.ecf_id)
    end

    it "serializes the `type`" do
      response = JSON.parse(described_class.render(delivery_partner))

      expect(response["type"]).to eq("delivery-partner")
    end
  end

  context "when serializing the v3 view" do
    describe "nested attributes" do
      subject(:attributes) { JSON.parse(described_class.render(delivery_partner, view: :v3, lead_provider: current_lead_provider))["attributes"] }

      it "serializes the `name`" do
        expect(attributes["name"]).to eq(delivery_partner.name)
      end

      it "serializes the cohorts" do
        expect(attributes["cohort"]).to eq([cohort_21.start_year, cohort_22.start_year])
      end

      it "serializes the `created_at`" do
        expect(attributes["created_at"]).to eq(delivery_partner.created_at.rfc3339)
      end

      it "serializes the `updated_at`" do
        expect(attributes["updated_at"]).to eq(delivery_partner.updated_at.rfc3339)
      end

      context "with multiple cohorts for the same year" do
        before do
          create(:delivery_partnership,
                 cohort: create(:cohort, start_year: 2021, suffix: 2),
                 lead_provider: current_lead_provider,
                 delivery_partner: delivery_partner)
        end

        it "serializes a unique list of cohort years" do
          expect(attributes["cohort"]).to eq([cohort_21.start_year, cohort_22.start_year])
        end
      end
    end
  end
end
