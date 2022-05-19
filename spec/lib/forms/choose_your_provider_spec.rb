require "rails_helper"

RSpec.describe Forms::ChooseYourProvider, type: :model do
  describe "validations" do
    let(:current_step) { "choose_your_provider" }
    let(:request) { nil }
    let(:course) { Course.find_by(name: "NPQ for Headship (NPQH)") }
    let(:school) { create(:school) }
    let(:works_in_school) { "yes" }
    let(:store) do
      {
        "teacher_catchment" => "england",
        "course_id" => course.id,
        "institution_identifier" => "School-#{school.urn}",
        "works_in_school" => works_in_school,
      }
    end
    let(:wizard) do
      RegistrationWizard.new(
        current_step: current_step,
        store: store,
        request: request,
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
      NPQEYL
      NPQLL
    ].freeze
    other_npq_codes = Course::COURSE_NAMES.keys - npqeyl_and_npqll_codes

    context "when trying to use non EYL/LL provider" do
      let(:lead_provider) { LeadProvider.find_by!(name: "Church of England") }

      context "when applying for an EYL/LL course" do
        let(:course_code) { npqeyl_and_npqll_codes.sample }
        let(:course_name) { Course::COURSE_NAMES[course_code] }
        let(:course) { Course.find_by(name: course_name) }

        it "returns an error" do
          subject.lead_provider_id = lead_provider.id
          subject.valid?
          expect(subject.errors[:lead_provider_id]).to be_present
        end
      end

      context "when applying for an non-EYL/LL course" do
        let(:course_code) { other_npq_codes.sample }
        let(:course_name) { Course::COURSE_NAMES[course_code] }
        let(:course) { Course.find_by(name: course_name) }

        it "returns an error" do
          subject.lead_provider_id = lead_provider.id
          subject.valid?
          expect(subject.errors[:lead_provider_id]).to be_blank
        end
      end
    end

    context "when trying to use EYL/LL provider" do
      let(:lead_provider) { LeadProvider.npqeyl_and_npqll_providers.sample }

      context "when applying for an EYL/LL course" do
        let(:course_code) { npqeyl_and_npqll_codes.sample }
        let(:course_name) { Course::COURSE_NAMES[course_code] }
        let(:course) { Course.find_by(name: course_name) }

        it "returns an error" do
          subject.lead_provider_id = lead_provider.id
          subject.valid?
          expect(subject.errors[:lead_provider_id]).to be_blank
        end
      end
    end
  end

  describe "#previous_step" do
    let(:current_step) { "choose_your_provider" }
    let(:request) { nil }
    let(:course) { Course.find_by(name: "NPQ for Headship (NPQH)") }
    let(:school) { create(:school) }
    let(:works_in_school) { "yes" }
    let(:store) do
      {
        "teacher_catchment" => "england",
        "course_id" => course.id,
        "institution_identifier" => "School-#{school.urn}",
        "works_in_school" => works_in_school,
      }
    end
    let(:wizard) do
      RegistrationWizard.new(
        current_step: current_step,
        store: store,
        request: request,
      )
    end
    let(:mock_funding_service) { instance_double(Services::FundingEligibility, "funded?": true) }

    before do
      subject.wizard = wizard
    end

    context "when npqh and eligible for funding" do
      before do
        allow(Services::FundingEligibility).to receive(:new).and_return(mock_funding_service)
      end

      it "returns :possible_funding" do
        expect(subject.previous_step).to eql(:possible_funding)
      end
    end

    context "international journey" do
      let(:store) do
        {
          "teacher_catchment" => "another",
        }
      end

      it "returns :funding_your_npq" do
        expect(subject.previous_step).to eql(:funding_your_npq)
      end
    end

    context "when not working in school" do
      let(:works_in_school) { "no" }

      it "returns :funding_your_npq" do
        expect(subject.previous_step).to eql(:funding_your_npq)
      end
    end
  end

  describe ".options" do
    subject do
      form.options
    end

    let(:form) { described_class.new }

    let(:store) do
      { "course_id" => course_id }
    end

    let(:course) { Course.ehco }
    let(:course_id) { course.id }

    let(:expected_providers) { LeadProvider.all }

    before do
      form.wizard = RegistrationWizard.new(
        current_step: :choose_your_npq,
        store: store,
        request: nil,
      )
    end

    npqeyl_and_npqll_codes = %w[
      NPQEYL
      NPQLL
    ].freeze
    other_npq_codes = Course::COURSE_NAMES.keys - npqeyl_and_npqll_codes

    other_npq_codes.each do |course_code|
      course_name = Course::COURSE_NAMES[course_code]

      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(name: course_name) }
        let(:expected_providers) { LeadProvider.all }

        it "returns all options" do
          expect(subject.map(&:value).sort).to eq(expected_providers.pluck(:id).sort)
        end
      end
    end

    npqeyl_and_npqll_codes.each do |course_code|
      course_name = Course::COURSE_NAMES[course_code]

      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(name: course_name) }
        let(:expected_providers) do
          LeadProvider.where(name: [
            "Ambition Institute",
            "Education Development Trust",
            "School-Led Network",
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
