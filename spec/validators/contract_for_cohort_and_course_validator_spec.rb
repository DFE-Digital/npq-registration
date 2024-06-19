# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContractForCohortAndCourseValidator do
  let(:klass) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      validates :cohort, contract_for_cohort_and_course: true

      attr_reader :lead_provider, :cohort, :course_identifier

      def self.model_name
        ActiveModel::Name.new(self, nil, "temp")
      end

      def initialize(lead_provider:, cohort:, course_identifier:)
        @lead_provider = lead_provider
        @cohort = cohort
        @course_identifier = course_identifier
      end
    end
  end

  describe "#validate" do
    let(:lead_provider) { LeadProvider.all.sample }
    let(:cohort) { create(:cohort, :current) }
    let(:course) { create(:course, :sl) }
    let!(:contract) { create(:contract, course:, cohort:, lead_provider:) }

    subject { klass.new(lead_provider:, cohort:, course_identifier:) }

    context "with a valid course" do
      let(:course_identifier) { course.identifier }

      it "is valid" do
        expect(subject).to be_valid
      end

      context "when lead provider has no contract for the cohort and course" do
        before { contract.update!(course: create(:course, :ehco)) }

        it "is invalid" do
          expect(subject).to be_invalid
        end

        it "has a meaningfull error", :aggregate_failures do
          expect(subject).to be_invalid
          expect(subject.errors.messages_for(:cohort))
            .to eq(["You cannot change a participant to this cohort as you do not have a contract for the cohort and course. Contact the DfE for assistance."])
        end
      end
    end

    context "with an invalid course" do
      let(:course_identifier) { "incorrect-course-identifier" }

      it "returns no errors" do
        expect(subject).to be_valid
        expect(subject.errors).to be_empty
      end
    end
  end
end
