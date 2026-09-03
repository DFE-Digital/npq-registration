require "rails_helper"

RSpec.describe Questionnaires::WorkSetting, type: :model do
  subject(:instance) { described_class.new(wizard:, work_setting:) }

  let(:wizard) { RegistrationWizard.new(current_step: :work_setting, store:, request: nil, current_user: nil) }
  let(:course_start_cohort) { create(:cohort, :capped).identifier }
  let(:course) { create(:course) }
  let(:teacher_catchment) { nil }
  let(:work_setting) { nil }

  let(:store) do
    {
      course_start_cohort:,
      teacher_catchment:,
      course_identifier: course.identifier,
    }.stringify_keys
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:work_setting) }
    it { is_expected.to validate_inclusion_of(:work_setting).in_array(described_class::ALL_SETTINGS) }

    it "rejects the 'a_school' value" do
      form = described_class.new(work_setting: described_class::A_SCHOOL)

      expect(form).to be_invalid
      expect(form).to have_error(:work_setting, :school_type_blank, "Select the type of school that you work in")
    end

    described_class::NESTED_SCHOOL_SETTINGS.each do |setting|
      it "accepts the nested school type '#{setting}'" do
        expect(described_class.new(work_setting: setting)).to be_valid
      end
    end
  end

  describe "#options" do
    subject(:school_option) { described_class.new.options.find { |option| option.value == described_class::A_SCHOOL } }

    it "nests the school types under 'a_school'" do
      expect(school_option).to be_nested
      expect(school_option.nested_options.map(&:value)).to eq(described_class::NESTED_SCHOOL_SETTINGS)
    end

    it "does not show the school types at the top level" do
      top_level = described_class.new.options.map(&:value)

      expect(top_level).not_to include(*described_class::NESTED_SCHOOL_SETTINGS)
    end
  end

  describe "#after_save" do
    {
      "a_school" => {
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
      },
      "primary_school" => {
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
      },
      "secondary_school" => {
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
      },
      "an_academy_trust" => {
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
      },
      "a_16_to_19_educational_setting" => {
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
      },
      "early_years_or_childcare" => {
        "works_in_school" => "no",
        "works_in_childcare" => "yes",
      },
      "other" => {
        "works_in_school" => "no",
        "works_in_childcare" => "no",
      },
    }.each do |option, expectations|
      context "when #{option}" do
        let(:work_setting) { option }
        let(:expecations) { expectations }

        before { instance.after_save }

        it "sets #{expectations} when '#{option}' is picked" do
          expecations.each_key do |field|
            expect(instance.wizard.store[field]).to eql(expectations[field])
          end
        end
      end
    end

    %w[a_school other].each do |setting|
      context "when #{setting}" do
        let(:store) { { "kind_of_nursery" => "Private nursery", "has_ofsted_urn" => "yes" } }
        let(:work_setting) { setting }

        let(:childcare_specific_keys) { %w[kind_of_nursery has_ofsted_urn] }

        it "deletes 'kind_of_nursery' and 'has_ofted_urn'" do
          expect(instance.wizard.store.keys).to include(*childcare_specific_keys)
          instance.after_save
          expect(instance.wizard.store.keys).not_to include(*childcare_specific_keys)
        end
      end
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when the user has answered they work in England" do
      let(:teacher_catchment) { "england" }

      context "when the work setting is a school" do
        let(:work_setting) { "a_school" }

        it { is_expected.to be :choose_school }
      end

      context "when the work setting is early years or childcare" do
        let(:work_setting) { "early_years_or_childcare" }

        it { is_expected.to be :kind_of_nursery }
      end

      context "when the work setting is another" do
        let(:work_setting) { "another_setting" }

        it { is_expected.to be :your_employment }
      end

      context "when the work setting is other" do
        let(:work_setting) { "other" }

        it { is_expected.to be :referred_by_return_to_teaching_adviser }
      end
    end

    context "when the user has answered they work outside of England" do
      let(:teacher_catchment) { "another" }

      it { is_expected.to be :ineligible_for_funding }
    end
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    let(:store) { { "declared_previous_funding" => declared_previous_funding } }

    context "when the user has declared previous funding" do
      let(:declared_previous_funding) { "yes" }

      it { is_expected.to be :ineligible_for_funding_previously_funded }

      context "when the course is EHCO" do
        let(:course) { create(:course, :early_headship_coaching_offer) }

        let(:store) do
          { declared_previous_funding: declared_previous_funding,
            course_identifier: course.identifier }.stringify_keys
        end

        it { is_expected.to be :funding_your_ehco }
      end
    end

    context "when the user has not declared previous funding" do
      let(:declared_previous_funding) { "no" }

      it { is_expected.to be :funding_history }
    end
  end
end
