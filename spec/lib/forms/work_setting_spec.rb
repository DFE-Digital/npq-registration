require "rails_helper"

RSpec.describe Forms::WorkSetting, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:work_setting) }
    it { is_expected.to validate_inclusion_of(:work_setting).in_array(described_class::ALL_SETTINGS) }
  end

  describe "#after_save" do
    let(:session) { {} }
    let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
    let(:wizard) { RegistrationWizard.new(current_step: :work_setting, store:, request:, current_user: create(:user)) }

    subject { described_class.new(work_setting:, wizard:) }

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
        let(:store) { {} }
        let(:work_setting) { option }
        let(:expecations) { expectations }

        before { subject.after_save }

        it "sets #{expectations} when '#{option}' is picked" do
          expecations.each_key do |field|
            expect(subject.wizard.store[field]).to eql(expectations[field])
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
          expect(subject.wizard.store.keys).to include(*childcare_specific_keys)
          subject.after_save
          expect(subject.wizard.store.keys).not_to include(*childcare_specific_keys)
        end
      end
    end
  end
end
