require "rails_helper"

RSpec.describe Questionnaires::ChooseYourNpq, type: :model do
  describe "validations" do
    let(:valid_course_identifier) { create(:course, :early_headship_coaching_offer).identifier }

    it { is_expected.to validate_presence_of(:course_identifier) }

    it "course for course_id must be available to applicant" do
      subject.course_identifier = create(:course, :additional_support_offer).identifier
      subject.valid?
      expect(subject.errors[:course_identifier]).to be_present

      subject.course_identifier = valid_course_identifier
      subject.valid?
      expect(subject.errors[:course_identifier]).to be_blank
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    let(:instance) { described_class.new(course_identifier: course.identifier) }
    let(:course) { create(:course, :leading_behaviour_culture) }
    let(:lead_provider) { LeadProvider.for(course:).first }
    let(:store) do
      {
        course_identifier: course.identifier,
        lead_provider_id: lead_provider.id,
      }.stringify_keys
    end

    before do
      instance.wizard = RegistrationWizard.new(
        current_step: :choose_your_npq,
        store:,
        request: nil,
        current_user: create(:user),
      )
    end

    context "when changing answers" do
      before do
        instance.flag_as_changing_answer
      end

      context "nothing was actually changed" do
        let(:course) { create(:course, :early_headship_coaching_offer) }

        it { is_expected.to be :check_answers }
      end

      context "when changing to something other than headship" do
        let(:course) { create(:course, :leading_teaching) }
        let(:school) { create(:school) }
        let(:previous_course) { create(:course, :headship) }
        let(:store) do
          {
            course_identifier: previous_course.identifier,
            institution_identifier: "School-#{school.urn}",
            works_in_school: "yes",
            lead_provider_id: lead_provider.id,
          }.stringify_keys
        end

        context "when lead provider is valid for new course" do
          it { is_expected.to be(:check_answers) }
        end

        context "when lead provider is not valid for new course" do
          let(:lead_provider) { LeadProvider.create(name: :foo) }

          it { is_expected.to be :ineligible_for_funding }
        end
      end
    end
  end

  describe "#previous_step" do
    let(:request) { nil }
    let(:store) do
      {
        teacher_catchment:,
        works_in_school:,
        works_in_childcare:,
        kind_of_nursery:,
        has_ofsted_urn:,
      }.stringify_keys
    end
    let(:teacher_catchment) { "another" }
    let(:works_in_school) { "no" }
    let(:works_in_childcare) { "no" }
    let(:kind_of_nursery) { nil }
    let(:has_ofsted_urn) { "no" }

    before do
      subject.wizard = RegistrationWizard.new(
        current_step: :choose_your_npq,
        store:,
        request:, current_user: create(:user)
      )
    end

    context "when inside catchment" do
      let(:teacher_catchment) { "england" }

      it "returns work_setting" do
        expect(subject.previous_step).to be(:work_setting)
      end

      context "when working in school" do
        let(:works_in_school) { "yes" }

        it "returns choose_school" do
          expect(subject.previous_step).to be(:choose_school)
        end
      end

      context "when working in childcare" do
        let(:works_in_childcare) { "yes" }

        it "return have_ofsted_urn" do
          expect(subject.previous_step).to be(:have_ofsted_urn)
        end

        context "when working for a public childcare provider" do
          let(:kind_of_nursery) { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.sample }

          it "return choose_childcare_provider" do
            expect(subject.previous_step).to be(:choose_childcare_provider)
          end
        end

        context "when working for a private childcare provider" do
          let(:kind_of_nursery) { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.sample }

          it "return have_ofsted_urn" do
            expect(subject.previous_step).to be(:have_ofsted_urn)
          end

          context "when user has declared they have an ofsted URN" do
            let(:has_ofsted_urn) { "yes" }

            it "return choose_private_childcare_provider" do
              expect(subject.previous_step).to be(:choose_private_childcare_provider)
            end
          end
        end
      end
    end
  end
end
