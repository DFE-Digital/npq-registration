require "rails_helper"

RSpec.describe Workplace do
  let(:school) { create :school }
  let(:local_authority) { create :local_authority }
  let(:private_childcare_provider) { create :private_childcare_provider }

  describe "all" do
    subject(:workplaces) { described_class.all.to_a }

    before { school && local_authority && private_childcare_provider }

    it "includes schools" do
      expect(workplaces).to include have_attributes(source_type: "School",
                                                    source_id: school.id,
                                                    source: school)
    end

    it "includes local authorities" do
      expect(workplaces).to include have_attributes(source_type: "LocalAuthority",
                                                    source_id: local_authority.id,
                                                    source: local_authority)
    end

    it "includes childcare providers" do
      expect(workplaces)
        .to include have_attributes(source_type: "PrivateChildcareProvider",
                                    source_id: private_childcare_provider.id,
                                    source: private_childcare_provider)
    end

    describe "ordering" do
      subject { workplaces.map(&:source_type) }

      it { is_expected.to eq %w[School PrivateChildcareProvider LocalAuthority] }
    end
  end

  describe "find" do
    context "with a School" do
      subject { described_class.find ["School", school.id] }

      it { is_expected.to have_attributes name: school.name, source: school }
      it { is_expected.to be_readonly }
    end

    context "with a LocalAuthority" do
      subject { described_class.find ["LocalAuthority", local_authority.id] }

      it { is_expected.to have_attributes name: local_authority.name, source: local_authority }
      it { is_expected.to be_readonly }
    end

    context "with a PrivateChildcareProvider" do
      subject(:workplace) do
        described_class.find ["PrivateChildcareProvider", private_childcare_provider.id]
      end

      it "finds the workplace for the childcare provider" do
        expect(workplace).to have_attributes name: private_childcare_provider.provider_name,
                                             source: private_childcare_provider
      end

      it { is_expected.to be_readonly }
    end
  end

  describe "pagination" do
    before { create_list :school, 7 }

    let :paged do
      Class.new {
        include Pagy::Backend

        def paged(page)
          pagy(Workplace.all, limit: 3, page:)
        end

        def params = {}
      }.new.paged(page)
    end

    let(:page) { 1 }

    context "with paged results" do
      subject { paged.last }

      it { is_expected.to have_attributes length: 3 }

      context "with later page" do
        let(:page) { 3 }

        it { is_expected.to have_attributes length: 1 }
      end
    end

    context "with pagination object" do
      subject { paged.first }

      it { is_expected.to have_attributes limit: 3, page: 1, count: 7 }
    end
  end

  describe ".search" do
    before do
      create :school, name: "London First School", urn: "001234"
      create :local_authority, name: "London Local Authority"
      create :private_childcare_provider, provider_name: "First steps forward",
                                          provider_urn: "EY1234"
    end

    context "with partial match at start" do
      subject { Workplace.search("london").map(&:name) }

      it { is_expected.to eq ["London First School", "London Local Authority"] }
    end

    context "with partial match in middle" do
      subject { Workplace.search("First").map(&:name) }

      it { is_expected.to eq ["London First School", "First steps forward"] }
    end

    context "with no match" do
      subject { Workplace.search("Manchester") }

      it { is_expected.to be_empty }
    end

    context "with no search value" do
      subject(:workplaces) { described_class.search(nil).map(&:name) }

      it "returns all workplaces" do
        expect(workplaces).to eq [
          "London First School",
          "First steps forward",
          "London Local Authority",
        ]
      end
    end

    context "with school urn" do
      subject { described_class.search("001234").map(&:name) }

      it { is_expected.to eq ["London First School"] }
    end

    context "with provider urn" do
      subject { described_class.search("EY1234").map(&:name) }

      it { is_expected.to eq ["First steps forward"] }
    end

    context "with unmatched urn" do
      subject { described_class.search("123456") }

      it { is_expected.to be_empty }
    end
  end
end
