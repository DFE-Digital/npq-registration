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

  describe "::search_by_name" do
    context "regarding apostrophes" do
      before do
        create(:school, name: "andrew's")
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
    end

    context "regarding hyphesn" do
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
    let(:urn) { "123" }
    let(:ukprn) { "123" }
    let(:institution) { build(:school, establishment_type_code: 28, urn:, ukprn:) } # 28 is academy

    context "when only school is on PP50 list" do
      before do
        stub_const("PP50_SCHOOLS_URN_HASH", { "123" => true })
      end

      context "when school is chosen as work setting" do
        let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }

        it "is a pp50_institution" do
          expect(institution.pp50?(work_setting)).to be true
        end
      end

      context "when FE is chosen as work setting" do
        let(:work_setting) { Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING }

        it "is not a pp50_institution" do
          expect(institution.pp50?(work_setting)).to be false
        end

        context "when the school is not in the pp50_further_education eligibility list" do
          it "is not a pp50_institution" do
            expect(institution.pp50?(work_setting)).to be false
          end
        end

        context "when the school is in the pp50_further_education eligibility list" do
          before { create(:eligibility_list, :pp50_further_education, identifier: ukprn) }

          it "is a pp50_institution" do
            expect(institution.pp50?(work_setting)).to be true
          end
        end

        context "when the school is in the PP50_FE_UKPRN_HASH but not in the pp50_further_education eligibility list" do
          let(:ukprn) { "10000599" } # UKPRN taken from data file

          before { create(:eligibility_list, :pp50_further_education, identifier: "123") }

          it "is not a pp50_institution" do
            expect(institution.pp50?(work_setting)).to be false
          end
        end
      end
    end

    context "when only FE is on PP50 list" do
      before do
        stub_const("PP50_FE_UKPRN_HASH", { "123" => true })
      end

      context "when FE is chosen as work setting" do
        let(:work_setting) { Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING }

        it "is a pp50_institution" do
          expect(institution.pp50?(work_setting)).to be true
        end
      end

      context "when school is chosen as work setting" do
        let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }

        it "is not a pp50_institution" do
          expect(institution.pp50?(work_setting)).to be false
        end

        context "when the school is not in the pp50_school eligibility list" do
          it "is not a pp50_institution" do
            expect(institution.pp50?(work_setting)).to be false
          end
        end

        context "when the school is in the pp50_school eligibility list" do
          before { create(:eligibility_list, :pp50_school, identifier: urn) }

          it "is a pp50_institution" do
            expect(institution.pp50?(work_setting)).to be true
          end
        end

        context "when the school is in the PP50_SCHOOLS_URN_HASH but not in the pp50_school eligibility list" do
          let(:urn) { "100006" } # URN taken from data file

          before { create(:eligibility_list, :pp50_school, identifier: "123") }

          it "is not a pp50_institution" do
            expect(institution.pp50?(work_setting)).to be false
          end
        end
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

    context "when the URN is not in the EY_OFSTED_URN_HASH" do
      let(:urn) { "100001" }

      it { is_expected.to be false }

      context "when the URN is in the disadvantaged_early_years_school eligibility list" do
        before { create(:eligibility_list, :disadvantaged_early_years_school, identifier: urn) }

        it { is_expected.to be true }
      end

      context "when the URN is in the EY_OFSTED_URN_HASH but not in the disadvantaged_early_years_school eligibility list" do
        let(:urn) { "150014" } # URN taken from data file

        before { create(:eligibility_list, :disadvantaged_early_years_school, identifier: "123") }

        it { is_expected.to be false }
      end
    end
  end

  describe "#la_disadvantaged_nursery?" do
    subject { school.la_disadvantaged_nursery? }

    let(:school) { create(:school, urn:) }

    context "when the URN is not in the LA_DISADVANTAGED_NURSERIES hash" do
      let(:urn) { "100001" }

      it { is_expected.to be false }

      context "when the URN is in the local_authority_nursery eligibility list" do
        before { create(:eligibility_list, :local_authority_nursery, identifier: urn) }

        it { is_expected.to be true }
      end

      context "when the URN is in the LA_DISADVANTAGED_NURSERIES hash but not in the local_authority_nursery eligibility list" do
        let(:urn) { "126565" } # URN taken from data file

        before { create(:eligibility_list, :local_authority_nursery, identifier: "123") }

        it { is_expected.to be false }
      end
    end
  end

  describe "#rise?" do
    subject { school.rise? }

    let(:school) { create(:school, urn:) }

    context "when the URN is not in the RISE_SCHOOLS hash" do
      let(:urn) { "100001" }

      it { is_expected.to be false }

      context "when the URN is in the rise_school eligibility list" do
        before { create(:eligibility_list, :rise_school, identifier: urn) }

        it { is_expected.to be true }
      end

      context "when the URN is in the rise.csv but not in the rise_school eligibility list" do
        let(:urn) { "112543" } # URN taken from data file

        before { create(:eligibility_list, :rise_school, identifier: "123") }

        it { is_expected.to be false }
      end
    end
  end

  describe "check PP50 CSV files are valid" do
    let(:school) { create(:school, urn:) }

    context "Local Authority Disadvantaged Nurseries (LA_DISADVANTAGED_NURSERIES)" do
      subject { school.la_disadvantaged_nursery? }

      let(:urn) { "126565" } # URN taken from data file

      it { is_expected.to be true }
    end

    context "PP50 Schools (PP50_SCHOOLS_URN_HASH)" do
      subject { school.pp50?(Questionnaires::WorkSetting::A_SCHOOL) }

      let(:urn) { "100006" } # URN taken from data file

      it { is_expected.to be true }
    end

    context "PP50 Further Education (PP50_FE_UKPRN_HASH)" do
      subject { school.pp50?(Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING) }

      let(:school) { create(:school, ukprn: "10000599") } # UKPRN taken from data file

      it { is_expected.to be true }
    end

    context "Early Years Schools (EY_OFSTED_URN_HASH)" do
      subject { school.eyl_disadvantaged? }

      let(:urn) { "150014" } # URN taken from data file

      it { is_expected.to be true }
    end
  end
end
