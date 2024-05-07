require "rails_helper"

RSpec.describe Questionnaires::ChooseYourProvider, type: :model do
  describe "validations" do
    let(:current_step) { "choose_your_provider" }
    let(:request) { nil }
    let(:course) { Course.find_by(identifier: "npq-headship") }
    let(:school) { create(:school) }
    let(:works_in_school) { "yes" }
    let(:store) do
      {
        "teacher_catchment" => "england",
        "course_identifier" => course.identifier,
        "institution_identifier" => "School-#{school.urn}",
        "works_in_school" => works_in_school,
      }
    end
    let(:wizard) do
      RegistrationWizard.new(
        current_step:,
        store:,
        request:,
        current_user: create(:user),
      )
    end

    before do
      subject.wizard = wizard
    end

    it { is_expected.to validate_presence_of(:lead_provider_id) }

    it "course for lead_provider_id must exist" do
      subject.lead_provider_id = 0
      subject.valid?
      expect(subject.errors[:lead_provider_id]).to be_present

      subject.lead_provider_id = LeadProvider.first.id
      subject.valid?
      expect(subject.errors[:lead_provider_id]).to be_blank
    end

    npqeyl_and_npqll_codes = %w[
      npq-early-years-leadership
      npq-leading-literacy
    ].freeze
    npqel_code = %w[
      npq-executive-leadership
    ].freeze
    npqh_sl_lt_ltd_lbc_ehco_codes = %w[
      npq-headship
      npq-senior-leadership
      npq-leading-teaching
      npq-leading-teaching-development
      npq-leading-behaviour-culture
      npq-early-headship-coaching-offer
      npq-additional-support-offer
    ].freeze
    npqlpm_codes = %w[
      npq-leading-primary-mathematics
    ]
    senco_codes = %w[
      npq-senco
    ]
    other_npq_codes = Course.pluck(:identifier) - npqeyl_and_npqll_codes - npqel_code - npqh_sl_lt_ltd_lbc_ehco_codes - npqlpm_codes - senco_codes

    other_npq_codes.each do |course_code|
      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(identifier: course_code) }
        let(:valid_lead_providers) { LeadProvider.all }

        let(:invalid_lead_providers) do
          LeadProvider.where.not(id: valid_lead_providers)
        end

        it "returns raises an error when an invalid lead provider is used" do
          valid_lead_providers.each do |valid_lead_provider|
            subject.lead_provider_id = valid_lead_provider.id
            subject.valid?
            expect(subject.errors[:lead_provider_id]).to be_blank
          end

          invalid_lead_providers.each do |invalid_lead_provider|
            subject.lead_provider_id = invalid_lead_provider.id
            subject.valid?
            expect(subject.errors[:lead_provider_id]).to be_present
          end
        end
      end
    end

    npqeyl_and_npqll_codes.each do |course_code|
      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(identifier: course_code) }
        let(:valid_lead_providers) do
          LeadProvider.where(name: [
            "Ambition Institute",
            "Education Development Trust",
            "National Institute of Teaching",
            "Teacher Development Trust",
            "Teach First",
            "UCL Institute of Education",
          ])
        end

        let(:invalid_lead_providers) do
          LeadProvider.where.not(id: valid_lead_providers)
        end

        it "returns raises an error when an invalid lead provider is used" do
          valid_lead_providers.each do |valid_lead_provider|
            subject.lead_provider_id = valid_lead_provider.id
            subject.valid?
            expect(subject.errors[:lead_provider_id]).to be_blank
          end

          invalid_lead_providers.each do |invalid_lead_provider|
            subject.lead_provider_id = invalid_lead_provider.id
            subject.valid?
            expect(subject.errors[:lead_provider_id]).to be_present
          end
        end
      end
    end

    npqel_code.each do |course_code|
      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(identifier: course_code) }
        let(:valid_lead_providers) do
          LeadProvider.where(name: [
            "Ambition Institute",
            "Best Practice Network (home of Outstanding Leaders Partnership)",
            "Church of England",
            "Education Development Trust",
            "LLSE",
            "National Institute of Teaching",
            "Teacher Development Trust",
            "Teach First",
            "UCL Institute of Education",
          ])
        end

        let(:invalid_lead_providers) do
          LeadProvider.where.not(id: valid_lead_providers)
        end

        it "returns raises an error when an invalid lead provider is used" do
          valid_lead_providers.each do |valid_lead_provider|
            subject.lead_provider_id = valid_lead_provider.id
            subject.valid?
            expect(subject.errors[:lead_provider_id]).to be_blank
          end

          invalid_lead_providers.each do |invalid_lead_provider|
            subject.lead_provider_id = invalid_lead_provider.id
            subject.valid?
            expect(subject.errors[:lead_provider_id]).to be_present
          end
        end
      end
    end

    npqh_sl_lt_ltd_lbc_ehco_codes.each do |course_code|
      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(identifier: course_code) }
        let(:valid_lead_providers) do
          LeadProvider.where(name: [
            "Ambition Institute",
            "Best Practice Network (home of Outstanding Leaders Partnership)",
            "Church of England",
            "Education Development Trust",
            "LLSE",
            "National Institute of Teaching",
            "Teacher Development Trust",
            "Teach First",
            "UCL Institute of Education",
          ])
        end

        let(:invalid_lead_providers) do
          LeadProvider.where.not(id: valid_lead_providers)
        end

        it "returns raises an error when an invalid lead provider is used" do
          valid_lead_providers.each do |valid_lead_provider|
            subject.lead_provider_id = valid_lead_provider.id
            subject.valid?
            expect(subject.errors[:lead_provider_id]).to be_blank
          end

          invalid_lead_providers.each do |invalid_lead_provider|
            subject.lead_provider_id = invalid_lead_provider.id
            subject.valid?
            expect(subject.errors[:lead_provider_id]).to be_present
          end
        end
      end
    end
  end

  describe "#previous_step" do
    let(:current_step) { "choose_your_provider" }
    let(:request) { nil }
    let(:course) { Course.find_by(identifier: "npq-headship") }
    let(:school) { create(:school) }
    let(:works_in_school) { "yes" }
    let(:store) do
      {
        "teacher_catchment" => "england",
        "course_identifier" => course.identifier,
        "institution_identifier" => "School-#{school.urn}",
        "works_in_school" => works_in_school,
      }
    end

    let(:wizard) do
      RegistrationWizard.new(
        current_step:,
        store:,
        request:,
        current_user: create(:user),
      )
    end

    let(:mock_funding_service) { instance_double(FundingEligibility, "funded?": true) }

    before do
      subject.wizard = wizard
    end

    context "when npqh and eligible for funding" do
      before do
        allow(FundingEligibility).to receive(:new).and_return(mock_funding_service)
      end

      it "returns :possible_funding" do
        expect(subject.previous_step).to be(:possible_funding)
      end
    end

    context "international journey" do
      let(:store) do
        {
          "teacher_catchment" => "another",
        }
      end

      it "returns :funding_your_npq" do
        expect(subject.previous_step).to be(:funding_your_npq)
      end
    end

    context "when not working in school" do
      let(:works_in_school) { "no" }

      it "returns :funding_your_npq" do
        expect(subject.previous_step).to be(:funding_your_npq)
      end
    end
  end

  describe ".options" do
    subject do
      form.options
    end

    let(:form) { described_class.new }

    let(:store) do
      {
        "course_identifier" => course_identifier,
      }
    end

    let(:course) { Course.ehco }
    let(:course_identifier) { course.identifier }

    let(:expected_providers) { LeadProvider.all }

    before do
      form.wizard = RegistrationWizard.new(
        current_step: :choose_your_npq,
        store:,
        request: nil,
        current_user: create(:user),
      )
    end

    npqeyl_and_npqll_codes = %w[
      npq-early-years-leadership
      npq-leading-literacy
    ].freeze
    npqel_code = %w[
      npq-executive-leadership
    ].freeze
    npqh_sl_lt_ltd_lbc_ehco_codes = %w[
      npq-headship
      npq-senior-leadership
      npq-leading-teaching
      npq-leading-teaching-development
      npq-leading-behaviour-culture
      npq-early-headship-coaching-offer
      npq-additional-support-offer
    ].freeze
    npqlpm_codes = %w[
      npq-leading-primary-mathematics
    ]
    senco_codes = %w[
      npq-senco
    ]
    other_npq_codes = Course.pluck(:identifier) - npqeyl_and_npqll_codes - npqel_code - npqh_sl_lt_ltd_lbc_ehco_codes - npqlpm_codes - senco_codes

    other_npq_codes.each do |course_code|
      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(identifier: course_code) }
        let(:expected_providers) { LeadProvider.all }

        it "returns all options" do
          expect(subject.map(&:value).sort).to eq(expected_providers.pluck(:id).sort)
        end
      end
    end

    npqeyl_and_npqll_codes.each do |course_code|
      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(identifier: course_code) }
        let(:expected_providers) do
          LeadProvider.where(name: [
            "Ambition Institute",
            "Education Development Trust",
            "National Institute of Teaching",
            "Teacher Development Trust",
            "Teach First",
            "UCL Institute of Education",
          ])
        end

        it "returns all options" do
          expect(subject.map(&:value).sort).to eq(expected_providers.pluck(:id).sort)
        end
      end
    end

    npqel_code.each do |course_code|
      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(identifier: course_code) }
        let(:expected_providers) do
          LeadProvider.where(name: [
            "Ambition Institute",
            "Best Practice Network (home of Outstanding Leaders Partnership)",
            "Church of England",
            "Education Development Trust",
            "LLSE",
            "National Institute of Teaching",
            "Teacher Development Trust",
            "Teach First",
            "UCL Institute of Education",
          ])
        end

        it "returns all options" do
          expect(subject.map(&:value).sort).to eq(expected_providers.pluck(:id).sort)
        end
      end
    end

    npqh_sl_lt_ltd_lbc_ehco_codes.each do |course_code|
      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(identifier: course_code) }
        let(:expected_providers) do
          LeadProvider.where(name: [
            "Ambition Institute",
            "Best Practice Network (home of Outstanding Leaders Partnership)",
            "Church of England",
            "Education Development Trust",
            "LLSE",
            "National Institute of Teaching",
            "Teacher Development Trust",
            "Teach First",
            "UCL Institute of Education",
          ])
        end

        it "returns all options" do
          expect(subject.map(&:value).sort).to eq(expected_providers.pluck(:id).sort)
        end
      end
    end
  end
end
