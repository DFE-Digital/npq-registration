require "rails_helper"

RSpec.describe DeliveryPartner, type: :model do
  describe "search scopes" do
    shared_examples "matching a delivery partner using" do |name:, existing_delivery_partner_name:|
      let(:matching_delivery_partner) { create :delivery_partner, name: existing_delivery_partner_name }
      let(:name) { name }

      before { matching_delivery_partner }

      it "matches '#{name}' to the delivery partner with name '#{existing_delivery_partner_name}'" do
        expect(subject).to include matching_delivery_partner
      end

      it "doesn't have duplicates" do
        expect(subject.uniq.count).to eq subject.count
      end
    end

    shared_examples "similarity matching" do
      context "when a delivery partner name has typos" do
        it_behaves_like "matching a delivery partner using", name: "The Julain TSH", existing_delivery_partner_name: "The Julian TSH" # one typo
        it_behaves_like "matching a delivery partner using", name: "The Julain THS", existing_delivery_partner_name: "The Julian TSH" # two typos
      end

      context "when a delivery partner name is similar" do
        it_behaves_like "matching a delivery partner using", name: "Alban Teaching School Hub", existing_delivery_partner_name: "Alban TSH"
        it_behaves_like "matching a delivery partner using", name: "The Alban Teaching School Hub", existing_delivery_partner_name: "Alban TSH"

        it_behaves_like "matching a delivery partner using", name: "Julian Teaching School Hub", existing_delivery_partner_name: "The Julian TSH"
        it_behaves_like "matching a delivery partner using", name: "The Julian Teaching School Hub", existing_delivery_partner_name: "The Julian TSH"

        it_behaves_like "matching a delivery partner using", name: "Julian TSH", existing_delivery_partner_name: "The Julian TSH"
        it_behaves_like "matching a delivery partner using", name: "East London TSH", existing_delivery_partner_name: "East London Teaching School Hub"
        it_behaves_like "matching a delivery partner using", name: "Julian TSH", existing_delivery_partner_name: "The Julian Teaching School Hub"

        it_behaves_like "matching a delivery partner using", name: "Alliance of Leading Learning", existing_delivery_partner_name: "ALL (Alliance of Leading Learning)"
        it_behaves_like "matching a delivery partner using", name: "Sacred Heart Alliance", existing_delivery_partner_name: "The Bishop Fraser Trust/Sacred Heart Alliance"
        it_behaves_like "matching a delivery partner using", name: "The Cardinal Vaughan Memorial School", existing_delivery_partner_name: "Kent Teaching School Hub/The Cardinal Vaughan Memorial School"
      end

      context "when there are many Teaching School Hubs" do
        let(:name) { "Some Teaching School Hub" }

        before do
          create_list(:delivery_partner, 20) do |delivery_partner|
            delivery_partner.name = "The #{Faker::Company.unique.name} Teaching School Hub"
            delivery_partner.save!
          end
        end

        it "doesn't return all the Teaching School Hubs" do
          expect(subject.count).to be < 20
        end
      end

      context "when there are many Delivery Partners beginning with 'The'" do
        let(:name) { "The Example School" }

        before do
          create_list(:delivery_partner, 20) do |delivery_partner|
            delivery_partner.name = "The #{Faker::Company.unique.name} School"
            delivery_partner.save!
          end
        end

        it "doesn't return all the Delivery Patners beginning with 'The'" do
          expect(subject.count).to be < 20
        end
      end
    end

    describe ".name_similar_to" do
      subject { described_class.name_similar_to(name) }

      context "when a delivery partner name matches exactly" do
        let(:name) { "The Example TSH" }

        before { create :delivery_partner, name: }

        it "doesn't return anything" do
          expect(subject).to be_empty
        end
      end

      it_behaves_like "similarity matching"
    end

    describe ".name_equal_or_similar_to" do
      subject { described_class.name_equal_or_similar_to(name) }

      context "when a delivery partner name matches exactly" do
        let(:name) { "The Example TSH" }

        before { create :delivery_partner, name: }

        it "returns the match" do
          expect(subject).to contain_exactly(an_object_having_attributes(name:))
        end
      end

      it_behaves_like "similarity matching"
    end

    describe ".search_with_synonyms" do
      let(:st_delivery_partner) { create(:delivery_partner, name: "St Matthew's Research School") }
      let(:saint_delivery_partner) { create(:delivery_partner, name: "Saint Matthew's Research School") }
      let(:delivery_partner_containing_st) { create(:school, name: "All Saints RC College") }

      before do
        st_delivery_partner
        saint_delivery_partner
        delivery_partner_containing_st
      end

      it "can find 'saint' when searching for 'st'" do
        expect(described_class.search_with_synonyms("st mary", :name_similar_to))
          .to include(st_delivery_partner, saint_delivery_partner)
      end

      it "can find 'st' when searching for 'saint'" do
        expect(described_class.search_with_synonyms("saint mary", :name_similar_to))
          .to include(st_delivery_partner, saint_delivery_partner)
      end

      it "does not return matches where 'st' is not a whole word" do
        expect(described_class.search_with_synonyms("some first", :name_similar_to))
          .not_to include(delivery_partner_containing_st)
      end
    end
  end

  describe "attributes" do
    subject { described_class.create(name: "new partner") }

    let(:uuid_format) { /\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/ }

    it { is_expected.to have_attributes ecf_id: uuid_format }
  end

  describe "relationships" do
    it { is_expected.to have_many(:delivery_partnerships) }
    it { is_expected.to have_many(:lead_providers).through(:delivery_partnerships) }
    it { is_expected.to have_many(:cohorts).through(:delivery_partnerships) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :name }

    describe "uniqueness" do
      before { create :delivery_partner }

      it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }
      it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    end
  end

  describe "#declarations" do
    subject { delivery_partner.declarations }

    let(:delivery_partner) { create :delivery_partner }
    let(:lead_provider) { create :lead_provider, delivery_partner: }
    let(:declaration_as_primary) { create :declaration, lead_provider:, delivery_partner: }

    it { is_expected.to include declaration_as_primary }

    context "when declared as secondary partner" do
      let(:another_partner) { create :delivery_partner, lead_provider: }

      let :declaration_as_secondary do
        create :declaration, lead_provider:,
                             delivery_partner: another_partner,
                             secondary_delivery_partner: delivery_partner
      end

      it { is_expected.to include declaration_as_secondary }
    end
  end

  describe "#cohorts_for_lead_provider" do
    subject { delivery_partner.cohorts_for_lead_provider(lead_provider) }

    let(:delivery_partner) { create :delivery_partner, lead_providers: { cohort => lead_provider, other_cohort => other_lead_provider } }
    let(:lead_provider) { create :lead_provider }
    let(:other_lead_provider) { create :lead_provider }
    let(:cohort) { create :cohort }
    let(:other_cohort) { create :cohort }

    before do
      create :delivery_partner, lead_providers: { cohort => lead_provider, other_cohort => other_lead_provider }
    end

    it { is_expected.to eq [cohort] }
  end
end
