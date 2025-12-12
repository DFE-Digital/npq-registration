require "rails_helper"

RSpec.describe School do
  describe ".primary_education_phase?" do
    let(:school) do
      build(:school,
            phase_name: phase)
    end
    let(:primary_phases) do
      [described_class::PRIMARY_PHASE,
       described_class::MIDDLE_DEEMED_PRIMARY_PHASE]
    end
    let(:non_primary_phase) { "Secondary" }

    context "when school phase_name is primary" do
      [described_class::PRIMARY_PHASE,
       described_class::MIDDLE_DEEMED_PRIMARY_PHASE].each do |phase|
        let(:phase) { phase }
        it "returns true" do
          expect(school).to be_primary_education_phase
        end
      end
    end

    context "when school phase_name is not primary" do
      let(:phase) { non_primary_phase }

      it "returns false" do
        expect(school).not_to be_primary_education_phase
      end
    end
  end

  describe ".search_by_name" do
    context "searching by name" do
      before { create(:school, name: "a school") }

      it "returns schools matching the name" do
        expect(described_class.search_by_name("a school").count).to be(1)
      end
    end

    context "searching by la_name" do
      before { create(:school, la_name: "Swindon") }

      it "returns schools matching the la_name" do
        expect(described_class.search_by_name("Swindon").count).to be(1)
      end
    end

    context "searching by address_1" do
      before { create(:school, address_1: "someplace") }

      it "returns schools matching the address_1" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by address_2" do
      before { create(:school, address_2: "someplace") }

      it "returns schools matching the address_2" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by address_3" do
      before { create(:school, address_3: "someplace") }

      it "returns schools matching the address_3" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by town" do
      before { create(:school, town: "someplace") }

      it "returns schools matching the town" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by county" do
      before { create(:school, county: "someplace") }

      it "returns schools matching the county" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by postcode" do
      before { create(:school, postcode: "AB12 3CD") }

      it "returns schools matching the postcode" do
        expect(described_class.search_by_name("AB12 3CD").count).to be(1)
      end
    end

    context "searching by postcode without spaces" do
      before { create(:school, postcode_without_spaces: "AB123CD") }

      it "returns schools matching the postcode without spaces" do
        expect(described_class.search_by_name("AB123CD").count).to be(1)
      end
    end

    context "searching by region" do
      before { create(:school, region: "someplace") }

      it "returns schools matching the region" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by URN" do
      before { create(:school, urn: "123456") }

      it "returns schools matching the URN" do
        expect(described_class.search_by_name("123456").count).to be(1)
      end
    end

    context "regarding apostrophes" do
      before do
        create(:school, name: "andrew's", postcode: "NW5")
      end

      it "can find with apostrophe" do
        expect(described_class.search_by_name("andrew's").count).to be(1)
      end

      it "can find without apostrophe" do
        expect(described_class.search_by_name("andrews").count).to be(1)
      end

      it "can find partial match" do
        expect(described_class.search_by_name("andrew").count).to be(1)
      end

      it "can return no matches" do
        expect(described_class.search_by_name("bob").open.count).to be(0)
      end
    end

    context "regarding hyphen" do
      before do
        create(:school, name: "mary-anne")
      end

      it "can find with hyphen" do
        expect(described_class.search_by_name("mary-anne").count).to be(1)
      end

      it "can find without hyphen" do
        expect(described_class.search_by_name("mary anne").count).to be(1)
      end

      it "can find partial match" do
        expect(described_class.search_by_name("mary").count).to be(1)
      end
    end

    context "synonym searching: st and saint" do
      let(:st_school) { create(:school, name: "St Mary's Catholic Primary School") }
      let(:saint_school) { create(:school, name: "Saint Mary's College") }
      let(:school_containing_st) { create(:school, name: "Some Firsaint School") }

      before do
        st_school
        saint_school
        school_containing_st
      end

      it "can find 'saint' when searching for 'st'" do
        expect(described_class.search_by_name("st mary")).to include(st_school, saint_school)
      end

      it "can find 'st' when searching for 'saint'" do
        expect(described_class.search_by_name("saint mary")).to include(st_school, saint_school)
      end

      it "does not return matches where 'st' is not a whole word" do
        expect(described_class.search_by_name("some first")).not_to include(school_containing_st)
      end
    end
  end

  describe "#in_england?" do
    it "returns true" do
      expect(subject).to be_in_england
    end

    context "when school establishment_type_code is 30 (Welsh establishment)" do
      before do
        subject.establishment_type_code = "30"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
      end
    end

    context "when school la_code is '673' (Vale of Glamorgan)" do
      before do
        subject.la_code = "673"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
      end
    end

    context "when school la_code is '702' (BFPO Overseas Establishments)" do
      before do
        subject.la_code = "702"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
      end
    end

    context "when school la_code is '000' (Does not apply)" do
      before do
        subject.la_code = "000"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
      end
    end

    context "when school la_code is '704' (Fieldwork Overseas Establishments)" do
      before do
        subject.la_code = "704"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
      end
    end

    context "when school la_code is '708' (Gibraltar Overseas Establishments)" do
      before do
        subject.la_code = "708"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
      end
    end
  end

  describe "#pp50?" do
    subject { institution.pp50?(work_setting) }

    let(:urn) { "123" }
    let(:ukprn) { "123" }
    let(:institution) { build(:school, establishment_type_code: 28, urn:, ukprn:) } # 28 is academy

    context "when school is chosen as work setting" do
      let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }

      context "when the school is in the pp50_further_education eligibility list" do
        before { create(:eligibility_list_entry, :pp50_further_education, identifier: ukprn) }

        it { is_expected.to be false }
      end

      context "when the school is in the pp50_school eligibility list" do
        before { create(:eligibility_list_entry, :pp50_school, identifier: urn) }

        it { is_expected.to be true }
      end
    end

    context "when FE is chosen as work setting" do
      let(:work_setting) { Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING }

      context "when the school is in the pp50_further_education eligibility list" do
        before { create(:eligibility_list_entry, :pp50_further_education, identifier: ukprn) }

        it { is_expected.to be true }
      end

      context "when the school is in the pp50_school eligibility list" do
        before { create(:eligibility_list_entry, :pp50_school, identifier: urn) }

        it { is_expected.to be false }
      end
    end
  end

  describe "#eligible_establishment?" do
    subject { school.eligible_establishment? }

    let(:school) { build(:school, establishment_type_code: code) }

    context "when establishment_type_code is in the list" do
      let(:code) { School::ELIGIBLE_ESTABLISHMENT_TYPE_CODES.keys.first }

      it { is_expected.to be true }
    end

    context "when establishment_type_code is not in the list" do
      let(:code) { "-1" }

      it { is_expected.to be false }
    end
  end

  describe "#eyl_disadvantaged?" do
    subject { school.eyl_disadvantaged? }

    let(:school) { create(:school, urn:) }
    let(:urn) { "100001" }

    context "when the URN is in the disadvantaged_early_years_school eligibility list" do
      before { create(:eligibility_list_entry, :disadvantaged_early_years_school, identifier: urn) }

      it { is_expected.to be true }
    end

    context "when the URN is not in the disadvantaged_early_years_school eligibility list" do
      it { is_expected.to be false }
    end
  end

  describe "#la_disadvantaged_nursery?" do
    subject { school.la_disadvantaged_nursery? }

    let(:school) { create(:school, urn:) }
    let(:urn) { "100001" }

    context "when the URN is in the local_authority_nursery eligibility list" do
      before { create(:eligibility_list_entry, :local_authority_nursery, identifier: urn) }

      it { is_expected.to be true }
    end

    context "when the URN is not in the local_authority_nursery eligibility list" do
      it { is_expected.to be false }
    end
  end

  describe "#rise?" do
    subject { school.rise? }

    let(:school) { create(:school, urn:) }
    let(:urn) { "100001" }

    context "when the URN is in the rise_school eligibility list" do
      before { create(:eligibility_list_entry, :rise_school, identifier: urn) }

      it { is_expected.to be true }
    end

    context "when the URN is not in the rise_school eligibility list" do
      it { is_expected.to be false }
    end
  end
end
