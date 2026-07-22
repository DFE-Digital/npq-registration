require "rails_helper"

RSpec.describe Questionnaires::WorkSetting, type: :model do
  subject(:instance) { described_class.new(wizard:, work_setting:) }

  let(:wizard) { RegistrationWizard.new(current_step: :work_setting, store:, request: nil, current_user: nil) }
  let(:store) { {} }
  let(:work_setting) { nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:work_setting) }
    it { is_expected.to validate_inclusion_of(:work_setting).in_array(described_class::ALL_SETTINGS) }
  end

  describe "#after_save" do
    {
      "a_school" => {
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

  describe "#previous_step" do
    subject { instance.previous_step }

    let(:store) { { "declared_previous_funding" => declared_previous_funding } }

    context "when the user has declared previous funding" do
      let(:declared_previous_funding) { "yes" }

      it { is_expected.to be :ineligible_for_funding_previously_funded }
    end

    context "when the user has not declared previous funding" do
      let(:declared_previous_funding) { "no" }

      it { is_expected.to be :funding_history }
    end
  end
end
