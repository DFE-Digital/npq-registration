# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContractForCohortAndCourseValidator do
  let(:klass) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      validates :cohort, contract_for_cohort_and_course: true

      attr_reader :cohort, :lead_provider, :course_identifier

      def self.model_name
        ActiveModel::Name.new(self, nil, "declarations/create")
      end

      def initialize(cohort:, lead_provider:, course_identifier:)
        @cohort = cohort
        @lead_provider = lead_provider
        @course_identifier = course_identifier
      end
    end
  end

  describe "#validate" do
    subject { klass.new(**params) }

    let(:params) { { cohort:, lead_provider:, course_identifier: } }

    let(:lead_provider) { create(:lead_provider) }
    let(:course) { create(:course, :senior_leadership) }
    let(:cohort) { create(:cohort, :current) }
    let(:statement) { create(:statement, cohort:, lead_provider:) }
    let!(:contract) { create(:contract, statement:, course:) }
    let(:course_identifier) { course.identifier }

    it "is valid" do
      expect(subject).to be_valid
    end

    context "when lead provider has no contract for the cohort and course" do
      before { contract.update!(course: create(:course, :leading_literacy)) }

      it { is_expected.to be_invalid }
      it { is_expected.to have_error(:cohort, :missing_contract_for_cohort_and_course, "You cannot submit a declaration for this participant as you do not have a contract for the cohort and course. Contact the DfE for assistance.") }
    end
  end
end
