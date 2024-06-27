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
  let!(:statement) { create(:statement, cohort:, lead_provider:) }

  subject(:service) { described_class.new(**params) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:participant_id).with_message("The property '#/participant_id' must be present") }
    it { is_expected.to validate_presence_of(:declaration_type).with_message("Enter a '#/declaration_type'.") }

    context "when lead providers don't match" do
      before { params[:lead_provider] = create(:lead_provider) }

      it "has a meaningful error", :aggregate_failures do
        expect(service).to be_invalid
        expect(service.errors.first).to have_attributes(attribute: :participant_id, type: :invalid_participant)
      end
    end

    context "when the course is invalid" do
      let(:course_identifier) { "any-course-identifier" }

      it "has a meaningful error", :aggregate_failures do
        expect(service).to be_invalid
        expect(service.errors.first).to have_attributes(attribute: :course_identifier, type: :inclusion)
      end
    end

    context "when declaration date is missing" do
      before { params[:declaration_date] = nil }

      it "has a meaningful error", :aggregate_failures do
        expect(service).to be_invalid
        expect(service.errors.first).to have_attributes(attribute: :declaration_date, type: :blank)
      end
    end

    context "when declaration date is invalid" do
      before { params[:declaration_date] = "2023-19-01T11:21:55Z" }

      it "has a meaningful error", :aggregate_failures do
        expect(service).to be_invalid
        expect(service.errors.first).to have_attributes(attribute: :declaration_date, type: :invalid)
      end
    end

    context "when declaration time is invalid" do
      before { params[:declaration_date] = "2023-19-01T29:21:55Z" }

      it "has a meaningful error", :aggregate_failures do
        expect(service).to be_invalid
        expect(service.errors.first).to have_attributes(attribute: :declaration_date, type: :invalid)
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

          expect(service.errors.first).to have_attributes(attribute: :participant_id, type: :declaration_must_be_before_withdrawal_date, options: { withdrawal_date: application.application_states.last.created_at.rfc3339 })
        end
      end
    end

    context "when an existing declaration already exists" do
      before { service.create_declaration }

      it "has a meaningful error" do
        expect(subject).to be_invalid

        expect(service.errors.first).to have_attributes(attribute: :base, type: :declaration_already_exists)
      end

      context "when the state submitted" do
        it "does not create duplicates" do
          expect { service.create_declaration }.not_to change(Declaration, :count)
        end
      end

      context "with an fundable participant" do
        let(:application) { create(:application, :eligible_for_funded_place, cohort:, course:, lead_provider:) }
        let(:existing_declaration) { Declaration.last }

        %w[eligible payable paid].each do |state|
          context "when the state is #{state}" do
            before { existing_declaration.update!(state:) }

            it "does not create duplicates" do
              expect { service.create_declaration }.not_to change(Declaration, :count)

              expect(existing_declaration.state).to eq(state)
            end
          end
        end
      end
    end

    context "when submitting completed" do
      let(:declaration_type) { "completed" }

      context "when has_passed is nil" do
        let(:has_passed) { nil }

        it "returns error" do
          expect(service).to be_invalid
          expect(service.errors.first).to have_attributes(attribute: :has_passed, type: :invalid)
        end
      end

      context "when has_passed is invalid text" do
        let(:has_passed) { "no_supported" }

        it "returns error" do
          expect(service).to be_invalid
          expect(service.errors.first).to have_attributes(attribute: :has_passed, type: :invalid)
        end
      end
    end

    context "when there are no available output fee statements" do
      before { lead_provider.next_output_fee_statement(cohort).update!(output_fee: false) }

      context "when the declarations is submitted" do
        it { is_expected.to be_valid }
      end

      context "when the declaration is eligible" do
        let(:application) { create(:application, :eligible_for_funded_place, cohort:, course:, lead_provider:) }

        it "returns an error" do
          expect(service).to be_invalid
          expect(service.errors.first).to have_attributes(attribute: :cohort, type: :no_output_fee_statement, options: { cohort: cohort.start_year })
        end
      end

      context "when there is an existing billable declaration" do
        before { create(:declaration, :paid, application:, declaration_date:) }

        it "returns an error" do
          expect(service).to be_invalid
          expect(service.errors.first).to have_attributes(attribute: :cohort, type: :no_output_fee_statement, options: { cohort: cohort.start_year })
        end
      end
    end
  end

  describe "#create_declaration" do
    subject { described_class.new(**params).create_declaration }

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

    context "when declaration is not fundable" do
      before do
        application.update(eligible_for_funding: true, funded_place: false)
      end

      it "sets the declaration to submitted" do
        subject

        declaration = Declaration.last
        expect(declaration).to be_submitted_state
      end
    end

    context "when posting for next cohort" do
      let(:cohort) { create(:cohort, :next) }
      let(:application) { create(:application, :eligible_for_funded_place, cohort:, course:, lead_provider:) }
      let!(:statement) { create(:statement, cohort:, lead_provider:, deadline_date: declaration_date + 6.weeks) }

      it "creates declaration to next cohort statement" do
        travel_to declaration_date + 1.day do
          expect { subject }.to change(Declaration, :count).by(1)

          declaration = Declaration.last

          expect(declaration).to be_eligible_state
          expect(declaration.statements).to include(statement)
        end
      end
    end

    context "when duplicate declaration exists" do
      let(:original_user) { create(:user, trn: participant.trn) }
      let(:original_application) { create(:application, :accepted, cohort:, course:, user: original_user) }
      let!(:original_declaration) { create(:declaration, application: original_application) }

      it "creates an `ineligible` declaration superseded by the original declaration" do
        subject

        declaration = Declaration.last

        expect(declaration).to be_ineligible_state
        expect(declaration.superseded_by).to eq(original_declaration)
      end
    end
  end
end
