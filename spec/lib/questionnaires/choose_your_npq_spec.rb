require "rails_helper"

RSpec.describe Questionnaires::ChooseYourNpq, type: :model do
  describe "validations" do
    let(:valid_course_identifier) do
      Course.where(display: true).sample.identifier
    end

    it { is_expected.to validate_presence_of(:course_identifier) }

    it "course for course_id must be available to applicant" do
      subject.course_identifier = Course.find_by(display: false).identifier
      subject.valid?
      expect(subject.errors[:course_identifier]).to be_present

      subject.course_identifier = valid_course_identifier
      subject.valid?
      expect(subject.errors[:course_identifier]).to be_blank
    end
  end

  describe "#next_step" do
    subject do
      described_class.new(course_identifier:)
    end

    let(:course_identifier) { Course.where(display: true).first.identifier }

    context "when changing answers" do
      before do
        subject.flag_as_changing_answer
      end

      context "nothing was actually changed" do
        let(:course_identifier) { "npq-headship" }
        let(:course) { Course.find_by(identifier: course_identifier) }
        let(:lead_provider) { LeadProvider.for(course:).first }
        let(:store) do
          {
            course_identifier: course.identifier,
            lead_provider_id: lead_provider.id,
          }.stringify_keys
        end
        let(:request) { nil }

        before do
          subject.wizard = RegistrationWizard.new(
            current_step: :choose_your_npq,
            store:,
            request:,
            current_user: create(:user),
          )
        end

        it "returns check_answers" do
          expect(subject.next_step).to be(:check_answers)
        end
      end

      context "when changing to something other than headship" do
        let(:course_identifier) { "npq-leading-teaching" }
        let(:course) { Course.find_by(identifier: course_identifier) }
        let(:school) { create(:school) }
        let(:previous_course) { Course.find_by(identifier: "npq-headship") }
        let(:lead_providers) { LeadProvider.for(course:) }
        let(:lead_provider) { lead_providers.first }
        let(:store) do
          {
            course_identifier: previous_course.identifier,
            institution_identifier: "School-#{school.urn}",
            works_in_school: "yes",
            lead_provider_id: lead_provider.id,
          }.stringify_keys
        end
        let(:request) { nil }

        before do
          subject.wizard = RegistrationWizard.new(
            current_step: :choose_your_npq,
            store:,
            request:, current_user: create(:user)
          )

          mock_previous_funding_api_request(
            course_identifier: "npq-headship",
            trn: "1234567",
            response: ecf_funding_lookup_response(previously_funded: false),
          )

          mock_previous_funding_api_request(
            course_identifier: "npq-leading-teaching",
            trn: "1234567",
            response: ecf_funding_lookup_response(previously_funded: false),
          )
        end

        context "when lead provider is valid for new course" do
          let(:lead_providers) { LeadProvider.for(course:) }

          it "returns check_answers" do
            expect(subject.next_step).to be(:check_answers)
          end
        end

        context "when lead provider is not valid for new course" do
          let(:lead_providers) { [LeadProvider.create(name: :foo)] }

          it "redirects you towards picking your provider flow" do
            expect(subject.next_step).to be(:ineligible_for_funding)
          end
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
