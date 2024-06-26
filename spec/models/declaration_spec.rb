require "rails_helper"

RSpec.describe Declaration, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:application) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:superseded_by).optional }
    it { is_expected.to have_many(:outcomes).dependent(:destroy) }
    it { is_expected.to have_many(:statement_items) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:declaration_type) }
    it { is_expected.to validate_presence_of(:declaration_date) }
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:course).to(:application) }
    it { is_expected.to delegate_method(:user).to(:application) }
    it { is_expected.to delegate_method(:identifier).to(:course).with_prefix(true) }
    it { is_expected.to delegate_method(:name).to(:lead_provider).with_prefix(true) }
  end

  describe "#uplift_paid?" do
    let(:declaration_type) { :started }
    let(:targeted_delivery_funding_eligibility) { true }
    let(:course_identifier) { Course::IDENTIFIERS.excluding(described_class::COURSE_IDENTIFIERS_INELIGIBLE_FOR_UPLIFT).sample }
    let(:state) { described_class::UPLIFT_PAID_STATES.sample }

    subject(:declaration) do
      application = build(:application, course: create(:course, identifier: course_identifier), targeted_delivery_funding_eligibility:)
      build(:declaration, application:, declaration_type:, state:)
    end

    it { is_expected.to be_uplift_paid }

    context "when targeted_delivery_funding_eligibility is false" do
      let(:targeted_delivery_funding_eligibility) { false }

      it { is_expected.not_to be_uplift_paid }
    end

    described_class.declaration_types.keys.excluding("started").each do |ineligible_declaration_type|
      context "when declaration_type is #{ineligible_declaration_type}" do
        let(:declaration_type) { ineligible_declaration_type }

        it { is_expected.not_to be_uplift_paid }
      end
    end

    Course::IDENTIFIERS.excluding(described_class::COURSE_IDENTIFIERS_INELIGIBLE_FOR_UPLIFT).each do |eligible_course_identifier|
      context "when course_identifier is #{eligible_course_identifier}" do
        let(:course_identifier) { eligible_course_identifier }

        it { is_expected.to be_uplift_paid }
      end
    end

    described_class::COURSE_IDENTIFIERS_INELIGIBLE_FOR_UPLIFT.each do |ineligible_course_identifier|
      context "when course_identifier is #{ineligible_course_identifier}" do
        let(:course_identifier) { ineligible_course_identifier }

        it { is_expected.not_to be_uplift_paid }
      end
    end

    described_class::UPLIFT_PAID_STATES.each do |eligible_state|
      context "when state is #{eligible_state}" do
        let(:state) { eligible_state }

        it { is_expected.to be_uplift_paid }
      end
    end

    described_class.states.keys.excluding(described_class::UPLIFT_PAID_STATES).each do |ineligible_state|
      context "when state is #{ineligible_state}" do
        let(:state) { ineligible_state }

        it { is_expected.not_to be_uplift_paid }
      end
    end
  end

  describe "#ineligible_for_funding_reason" do
    let(:state) { :ineligible }
    let(:state_reason) { nil }
    let(:declaration) { build(:declaration, state:, state_reason:) }

    subject { declaration.ineligible_for_funding_reason }

    it { is_expected.to be_nil }

    context "when the state_reason is 'duplicate'" do
      let(:state_reason) { "duplicate" }

      it { is_expected.to eq("duplicate_declaration") }
    end

    described_class.states.keys.excluding("ineligible").each do |ineligible_state|
      context "when the state is #{ineligible_state}" do
        let(:state) { ineligible_state }

        it { is_expected.to be_nil }
      end
    end
  end

  describe "#eligible_for_payment?" do
    subject { build(:declaration, state:) }

    described_class::ELIGIBLE_FOR_PAYMENT_STATES.each do |eligible_state|
      context "when the state is #{eligible_state}" do
        let(:state) { eligible_state }

        it { is_expected.to be_eligible_for_payment }
      end
    end

    described_class.states.keys.excluding(described_class::ELIGIBLE_FOR_PAYMENT_STATES).each do |ineligible_state|
      context "when the state is #{ineligible_state}" do
        let(:state) { ineligible_state }

        it { is_expected.not_to be_eligible_for_payment }
      end
    end
  end

  describe "#voidable?" do
    subject { build(:declaration, state:) }

    described_class::VOIDABLE_STATES.each do |eligible_state|
      context "when the state is #{eligible_state}" do
        let(:state) { eligible_state }

        it { is_expected.to be_voidable }
      end
    end

    described_class.states.keys.excluding(described_class::VOIDABLE_STATES).each do |ineligible_state|
      context "when the state is #{ineligible_state}" do
        let(:state) { ineligible_state }

        it { is_expected.not_to be_voidable }
      end
    end
  end

  describe "#billable_statement" do
    let(:statement_item) { create(:statement_item, state: :payable) }
    let(:declaration) { statement_item.declaration }

    subject { declaration.billable_statement }

    it { is_expected.to eq(statement_item.statement) }

    context "when there are no billable statement items" do
      let(:statement_item) { create(:statement_item, state: :awaiting_clawback) }

      it { is_expected.to be_nil }
    end
  end

  describe "#refundable_statement" do
    let(:statement_item) { create(:statement_item, state: :awaiting_clawback) }
    let(:declaration) { statement_item.declaration }

    subject { declaration.refundable_statement }

    it { is_expected.to eq(statement_item.statement) }

    context "when there are no refundable statement items" do
      let(:statement_item) { create(:statement_item, state: :payable) }

      it { is_expected.to be_nil }
    end
  end

  describe "scopes" do
    let(:declarations) { Declaration.states.keys.map { |state| create(:declaration, state:) } }

    describe ".billable" do
      it "returns declarations with billable states" do
        billable_declarations = declarations.select { |d| %w[eligible payable paid].include?(d.state) }

        expect(Declaration.billable).to match_array(billable_declarations)
      end
    end

    describe ".changeable" do
      it "returns declarations with changeable states" do
        changeable_declarations = declarations.select { |d| %w[eligible submitted].include?(d.state) }

        expect(Declaration.changeable).to match_array(changeable_declarations)
      end
    end

    describe ".billable_or_changeable" do
      it "returns declarations with either billable or changeable states" do
        states = %w[submitted eligible payable paid]
        billable_or_changeable = declarations.select { |d| states.include?(d.state) }

        expect(Declaration.billable_or_changeable).to match_array(billable_or_changeable)
      end
    end
  end
end
