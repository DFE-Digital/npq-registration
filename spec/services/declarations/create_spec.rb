# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::Create, type: :model do
  let(:lead_provider) { LeadProvider.all.sample }
  let(:cohort) { create(:cohort, :current) }
  let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
  let(:course) { create(:course, :sl, course_group:) }
  let!(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
  let(:application) { create(:application, :accepted, cohort:, course:, lead_provider:) }
  let(:participant) { application.user }
  let(:participant_id) { participant.ecf_id }
  let(:declaration_type) { "started" }
  let(:declaration_date) { schedule.applies_from + 1.day }
  let(:course_identifier) { course.identifier }
  let(:has_passed) { true }
  let(:params) do
    {
      lead_provider:,
      participant_id:,
      declaration_type:,
      declaration_date: declaration_date.rfc3339,
      course_identifier:,
      has_passed:,
    }
  end

  before { create(:contract, course:, cohort:, lead_provider:) }

  subject(:service) { described_class.new(**params) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:participant_id).with_message("The property '#/participant_id' must be present") }
    it { is_expected.to validate_presence_of(:declaration_type).with_message("Enter a '#/declaration_type'.") }

    context "when lead providers don't match" do
      before { params[:lead_provider] = create(:lead_provider) }

      it "has a meaningful error", :aggregate_failures do
        expect(service).to be_invalid
        expect(service.errors.messages_for(:participant_id)).to eq(["Your update cannot be made as the '#/participant_id' is not recognised. Check participant details and try again."])
      end
    end

    context "when the course is invalid" do
      let(:course_identifier) { "any-course-identifier" }

      it "has a meaningful error", :aggregate_failures do
        expect(service).to be_invalid
        expect(service.errors.messages_for(:course_identifier)).to eq(["The entered '#/course_identifier' is not recognised for the given participant. Check details and try again."])
      end
    end

    context "when declaration date is missing" do
      before { params[:declaration_date] = nil }

      it "has a meaningful error", :aggregate_failures do
        expect(service).to be_invalid
        expect(service.errors.messages_for(:declaration_date)).to include("Enter a '#/declaration_date'.")
      end
    end

    context "when declaration date is invalid" do
      before { params[:declaration_date] = "2023-19-01T11:21:55Z" }

      it "has a meaningful error", :aggregate_failures do
        expect(service).to be_invalid
        expect(service.errors.messages_for(:declaration_date)).to include("Enter a valid RCF3339 '#/declaration_date'.")
      end
    end

    context "when declaration time is invalid" do
      before { params[:declaration_date] = "2023-19-01T29:21:55Z" }

      it "has a meaningful error", :aggregate_failures do
        expect(service).to be_invalid
        expect(service.errors.messages_for(:declaration_date)).to include("Enter a valid RCF3339 '#/declaration_date'.")
      end
    end

    context "when a participant has been withdrawn" do
      before do
        travel_to(withdrawal_time) do
          ApplicationState.create!(application:, lead_provider:, state: :withdrawn)
          application.withdrawn!
        end
      end

      context "when the declaration is made after the participant has been withdrawn" do
        let(:withdrawal_time) { declaration_date - 1.day }

        it "has a meaningful error" do
          expect(subject).to be_invalid

          expect(service.errors.messages_for(:participant_id)).to eq(["This participant withdrew from this course on #{application.application_states.last.created_at.rfc3339}. Enter a '#/declaration_date' that's on or before the withdrawal date."])
        end
      end
    end

    context "when an existing declaration already exists" do
      before { service.save }

      context "when the state submitted" do
        it "does create duplicates" do
          expect { service.save }.not_to change(Declaration, :count)
        end
      end
    end

    context "when submitting completed" do
      let(:declaration_type) { "completed" }

      context "when has_passed is nil" do
        let(:has_passed) { nil }

        it "returns error" do
          expect(service).to be_invalid
          expect(service.errors.messages_for(:has_passed)).to eq(["Enter 'true' or 'false' in the '#/has_passed' field to indicate whether this participant has passed or failed their course."])
        end
      end

      context "when has_passed is invalid text" do
        let(:has_passed) { "no_supported" }

        it "returns error" do
          expect(service).to be_invalid
          expect(service.errors.messages_for(:has_passed)).to eq(["Enter 'true' or 'false' in the '#/has_passed' field to indicate whether this participant has passed or failed their course."])
        end
      end
    end
  end

  describe "#save" do
    subject { described_class.new(**params).save }

    it "creates a declaration" do
      expect { subject }.to change(Declaration, :count).by(1)
    end

    it "stores the correct data" do
      subject

      declaration = Declaration.last

      expect(declaration.declaration_type).to eq(declaration_type)
      expect(declaration.user.ecf_id).to eq(participant.ecf_id)
      expect(declaration.course_identifier).to eq(course_identifier)
      expect(declaration.lead_provider).to eq(lead_provider)
      expect(declaration.cohort).to eq(cohort)
    end

    context "when declaration is `submitted`" do
      let(:application) { create(:application, :eligible_for_funded_place, cohort:, course:, lead_provider:) }

      it "calls `StatementAttacher`" do
        expect_any_instance_of(Declarations::StatementAttacher).to receive(:attach)

        subject
      end
    end
  end
end
