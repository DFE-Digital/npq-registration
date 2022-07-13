require "rails_helper"

RSpec.describe Forms::ChooseYourNpq, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:course_id) }

    it "course for course_id must exist" do
      subject.course_id = 0
      subject.valid?
      expect(subject.errors[:course_id]).to be_present

      subject.course_id = Course.where(display: true).first.id
      subject.valid?
      expect(subject.errors[:course_id]).to be_blank
    end

    it "course for course_id must be available to applicant" do
      subject.course_id = Course.where(display: false).first
      subject.valid?
      expect(subject.errors[:course_id]).to be_present

      subject.course_id = Course.where(display: true).first.id
      subject.valid?
      expect(subject.errors[:course_id]).to be_blank
    end
  end

  describe "#next_step" do
    subject do
      described_class.new(course_id: course.id.to_s)
    end

    context "when changing answers" do
      before do
        subject.flag_as_changing_answer
      end

      context "nothing was actually changed" do
        let(:course) { Course.find_by(name: "NPQ for Headship (NPQH)") }
        let(:lead_provider) { LeadProvider.for(course:).first }
        let(:store) do
          {
            course_id: course.id.to_s,
            lead_provider_id: lead_provider.id,
          }.stringify_keys
        end
        let(:request) { nil }

        before do
          subject.wizard = RegistrationWizard.new(
            current_step: :choose_your_npq,
            store:,
            request:,
          )
        end

        it "returns check_answers" do
          expect(subject.next_step).to eql(:check_answers)
        end
      end

      context "when changing to something other than headship" do
        let(:course) { Course.find_by(name: "NPQ for Leading Teaching (NPQLT)") }
        let(:school) { create(:school) }
        let(:previous_course) { Course.find_by(name: "NPQ for Headship (NPQH)") }
        let(:lead_providers) { LeadProvider.for(course:) }
        let(:lead_provider) { lead_providers.first }
        let(:store) do
          {
            course_id: previous_course.id.to_s,
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
            request:,
          )

          stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding?npq_course_identifier=npq-headship")
            .with(
              headers: {
                "Authorization" => "Bearer ECFAPPBEARERTOKEN",
              },
            )
            .to_return(
              status: 200,
              body: previously_funded_response(false),
              headers: {
                "Content-Type" => "application/vnd.api+json",
              },
            )

          stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding?npq_course_identifier=npq-leading-teaching")
            .with(
              headers: {
                "Authorization" => "Bearer ECFAPPBEARERTOKEN",
              },
            )
            .to_return(
              status: 200,
              body: previously_funded_response(false),
              headers: {
                "Content-Type" => "application/vnd.api+json",
              },
            )
        end

        context "when lead provider is valid for new course" do
          let(:lead_providers) { LeadProvider.for(course:) }

          it "returns check_answers" do
            expect(subject.next_step).to eql(:check_answers)
          end
        end

        context "when lead provider is not valid for new course" do
          let(:lead_providers) { LeadProvider.where.not(id: LeadProvider.for(course:)) }

          it "redirects you towards picking your provider flow" do
            expect(subject.next_step).to eql(:ineligible_for_funding)
          end
        end
      end
    end
  end

  describe "#previous_step" do
    let(:request) { nil }

    before do
      subject.wizard = RegistrationWizard.new(
        current_step: :choose_your_npq,
        store:,
        request:,
      )
    end

    let(:store) do
      {
        teacher_catchment:,
        works_in_school:,
        works_in_childcare:,
        works_in_nursery:,
        kind_of_nursery:,
        has_ofsted_urn:,
      }.stringify_keys
    end

    let(:teacher_catchment) { "another" }
    let(:works_in_school) { "no" }
    let(:works_in_childcare) { "no" }
    let(:works_in_nursery) { "no" }
    let(:kind_of_nursery) { nil }
    let(:has_ofsted_urn) { "no" }

    context "when inside catchment" do
      let(:teacher_catchment) { "england" }

      it "returns work_in_childcare" do
        expect(subject.previous_step).to eql(:work_in_childcare)
      end

      context "when working in school" do
        let(:works_in_school) { "yes" }

        it "returns choose_school" do
          expect(subject.previous_step).to eql(:choose_school)
        end
      end

      context "when working in childcare" do
        let(:works_in_childcare) { "yes" }

        it "return have_ofsted_urn" do
          expect(subject.previous_step).to eql(:have_ofsted_urn)
        end

        context "when working in a nursery" do
          let(:works_in_nursery) { "yes" }

          it "return have_ofsted_urn" do
            expect(subject.previous_step).to eql(:have_ofsted_urn)
          end

          context "when working for a public childcare provider" do
            let(:kind_of_nursery) { Forms::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.sample }

            it "return choose_childcare_provider" do
              expect(subject.previous_step).to eql(:choose_childcare_provider)
            end
          end

          context "when working for a private childcare provider" do
            let(:kind_of_nursery) { Forms::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.sample }

            it "return have_ofsted_urn" do
              expect(subject.previous_step).to eql(:have_ofsted_urn)
            end

            context "when user has declared they have an ofsted URN" do
              let(:has_ofsted_urn) { "yes" }

              it "return choose_private_childcare_provider" do
                expect(subject.previous_step).to eql(:choose_private_childcare_provider)
              end
            end
          end
        end
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
        "works_in_school" => works_in_school,
        "teacher_catchment" => teacher_catchment,
        "works_in_childcare" => works_in_childcare,
      }
    end

    let(:works_in_school) { "no" }
    let(:teacher_catchment) { "scotland" }
    let(:works_in_childcare) { "no" }

    let(:expected_courses) { Course.where(display: true) }

    before do
      form.wizard = RegistrationWizard.new(
        current_step: :choose_your_npq,
        store:,
        request: nil,
      )
    end

    context "when inside catchment" do
      let(:teacher_catchment) { "england" }

      context "when not working in school or childcare" do
        let(:works_in_school) { "no" }
        let(:works_in_childcare) { "no" }

        it "returns all options" do
          expect(subject.map(&:value).sort).to eq(expected_courses.pluck(:id).sort)
        end
      end

      context "when working in a school" do
        let(:works_in_school) { "yes" }

        it "returns all options" do
          expect(subject.map(&:value).sort).to eq(expected_courses.pluck(:id).sort)
        end
      end

      context "when working in childcare" do
        let(:works_in_childcare) { "yes" }

        it "returns all options" do
          expect(subject.map(&:value).sort).to eq(expected_courses.pluck(:id).sort)
        end
      end
    end

    context "when outside catchment" do
      let(:teacher_catchment) { "scotland" }

      context "when not working in school or childcare" do
        let(:works_in_school) { "no" }
        let(:works_in_childcare) { "no" }

        it "returns all options" do
          expect(subject.map(&:value).sort).to eq(expected_courses.pluck(:id).sort)
        end
      end

      context "when working in a school" do
        let(:works_in_school) { "yes" }

        it "returns all options" do
          expect(subject.map(&:value).sort).to eq(expected_courses.pluck(:id).sort)
        end
      end

      context "when working in childcare" do
        let(:works_in_childcare) { "yes" }

        it "returns all options" do
          expect(subject.map(&:value).sort).to eq(expected_courses.pluck(:id).sort)
        end
      end
    end
  end
end
