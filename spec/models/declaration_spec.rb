require "rails_helper"

RSpec.describe Declaration, type: :model do
  subject { build(:declaration) }

  describe "associations" do
    it { is_expected.to belong_to(:application) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:superseded_by).optional }
    it { is_expected.to have_many(:participant_outcomes).dependent(:destroy) }
    it { is_expected.to have_many(:statement_items) }
    it { is_expected.to have_many(:statements).through(:statement_items) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:declaration_type) }
    it { is_expected.to validate_presence_of(:declaration_date) }

    context "when the declaration_date is in the future" do
      before { subject.declaration_date = 1.day.from_now }

      it "has an error on create" do
        expect(subject.save).to be_falsey
        expect(subject).to have_error(:declaration_date, :future_declaration_date, "The '#/declaration_date' value cannot be a future date. Check the date and try again.")
      end

      it "has an error on update" do
        subject.declaration_date = 1.day.ago
        expect(subject.save).to be_truthy

        subject.declaration_date = 1.day.from_now
        expect(subject.save).to be_falsey
        expect(subject).to have_error(:declaration_date, :future_declaration_date, "The '#/declaration_date' value cannot be a future date. Check the date and try again.")
      end
    end

    context "when declaration_date is before the schedule start" do
      before { subject.declaration_date = subject.application.schedule.applies_from.prev_week }

      it "has a meaningful error" do
        expect(subject).to be_invalid
        expect(subject).to have_error(:declaration_date, :declaration_before_schedule_start, "Enter a '#/declaration_date' that's on or after the schedule start.")
      end
    end

    context "when declaration_date is at the schedule start" do
      before { subject.declaration_date = subject.application.schedule.applies_from }

      it { is_expected.to be_valid }
    end
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:course).to(:application) }
    it { is_expected.to delegate_method(:user).to(:application) }
    it { is_expected.to delegate_method(:identifier).to(:course).with_prefix(true) }
    it { is_expected.to delegate_method(:name).to(:lead_provider).with_prefix(true) }
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:state).with_values(
        submitted: "submitted",
        eligible: "eligible",
        payable: "payable",
        paid: "paid",
        voided: "voided",
        ineligible: "ineligible",
        awaiting_clawback: "awaiting_clawback",
        clawed_back: "clawed_back",
      ).backed_by_column_of_type(:enum).with_suffix
    }

    it {
      expect(subject).to define_enum_for(:declaration_type).with_values(
        started: "started",
        "retained-1": "retained-1",
        "retained-2": "retained-2",
        completed: "completed",
      ).backed_by_column_of_type(:enum).with_suffix
    }

    it {
      expect(subject).to define_enum_for(:state_reason).with_values(
        duplicate: "duplicate",
      ).backed_by_column_of_type(:enum).with_suffix
    }
  end

  describe "state transition" do
    let(:declaration) { create(:declaration, state:) }

    describe ".mark_eligible" do
      let(:state) { :submitted }

      it { expect { declaration.mark_eligible }.to change(declaration, :state).from("submitted").to("eligible") }

      context "when not submitted" do
        let(:state) { :paid }

        it { expect { declaration.mark_eligible! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".mark_payable" do
      let(:state) { :eligible }

      it { expect { declaration.mark_payable }.to change(declaration, :state).from("eligible").to("payable") }

      context "when not eligible" do
        let(:state) { :paid }

        it { expect { declaration.mark_payable! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".mark_paid" do
      let(:state) { :payable }

      it { expect { declaration.mark_paid }.to change(declaration, :state).from("payable").to("paid") }

      context "when not payable" do
        let(:state) { :paid }

        it { expect { declaration.mark_payable! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".mark_ineligible" do
      context "when submitted" do
        let(:state) { :submitted }

        it { expect { declaration.mark_ineligible }.to change(declaration, :state).from("submitted").to("ineligible") }
      end

      context "when not submitted/eligible/payable/paid" do
        let(:state) { :voided }

        it { expect { declaration.mark_ineligible! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".mark_awaiting_clawback" do
      let(:state) { :paid }

      it { expect { declaration.mark_awaiting_clawback }.to change(declaration, :state).from("paid").to("awaiting_clawback") }

      context "when not paid" do
        let(:state) { :payable }

        it { expect { declaration.mark_awaiting_clawback! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".mark_clawed_back" do
      let(:state) { :awaiting_clawback }

      it { expect { declaration.mark_clawed_back }.to change(declaration, :state).from("awaiting_clawback").to("clawed_back") }

      context "when not awaiting_clawback" do
        let(:state) { :clawed_back }

        it { expect { declaration.mark_clawed_back! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".mark_voided" do
      context "when submitted" do
        let(:state) { :submitted }

        it { expect { declaration.mark_voided }.to change(declaration, :state).from("submitted").to("voided") }
      end

      context "when eligible" do
        let(:state) { :eligible }

        it { expect { declaration.mark_voided }.to change(declaration, :state).from("eligible").to("voided") }
      end

      context "when payable" do
        let(:state) { :payable }

        it { expect { declaration.mark_voided }.to change(declaration, :state).from("payable").to("voided") }
      end

      context "when ineligible" do
        let(:state) { :ineligible }

        it { expect { declaration.mark_voided }.to change(declaration, :state).from("ineligible").to("voided") }
      end

      context "when not submitted/eligible/payable/ineligible" do
        let(:state) { :paid }

        it { expect { declaration.mark_voided! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end
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

    context "when the state is payable" do
      let(:state) { :payable }

      it { is_expected.to be_eligible_for_payment }
    end

    context "when the state is eligible" do
      let(:state) { :eligible }

      it { is_expected.to be_eligible_for_payment }
    end

    described_class.states.keys.excluding("payable", "eligible").each do |eligible_state|
      context "when the state is #{eligible_state}" do
        let(:state) { eligible_state }

        it { is_expected.not_to be_eligible_for_payment }
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
    describe ".latest_first" do
      let!(:latest_declaration) { create(:declaration) }
      let!(:older_declaration) { travel_to(1.day.ago) { create(:declaration) } }

      it "returns the declarations with those created latest first" do
        expect(described_class.latest_first).to eq([latest_declaration, older_declaration])
      end
    end

    describe ".eligible_for_outcomes" do
      subject { described_class.eligible_for_outcomes(lead_provider, course_identifier) }

      let(:lead_provider) { completed_declaration.lead_provider }
      let(:course_identifier) { completed_declaration.course_identifier }
      let(:completed_declaration) { create(:declaration, :completed, :payable) }
      let(:course) { completed_declaration.course }
      let(:older_completed_declaration) { travel_to(1.day.ago) { create(:declaration, :completed, :payable, course:, lead_provider:) } }

      before do
        # Not a completed declaration.
        completed_declaration.dup.update!(declaration_type: "retained-1")

        # Declaration on another provider.
        completed_declaration.dup.update!(lead_provider: LeadProvider.where.not(id: lead_provider.id).first)

        # Declaration with different course.
        completed_declaration.dup.update!(application: create(:application, course: create(:course, identifier: "other-course")))

        # Declarations that are not billable or voidable.
        Declaration.states.keys.excluding(Declaration::BILLABLE_STATES + Declaration::VOIDABLE_STATES).each do |state|
          completed_declaration.dup.update!(state:)
        end
      end

      it { is_expected.to eq([completed_declaration, older_completed_declaration]) }

      context "when there are no declarations" do
        before { Declaration.destroy_all }

        it { is_expected.to be_empty }
      end
    end

    describe "declaration states" do
      let(:declarations) { described_class.states.keys.map { |state| create(:declaration, state:) } }

      describe ".billable" do
        it "returns declarations with billable states" do
          billable_declarations = declarations.select { |d| %w[eligible payable paid].include?(d.state) }

          expect(described_class.billable).to match_array(billable_declarations)
        end
      end

      describe ".voidable" do
        it "returns declarations with voidable states" do
          voidable_declarations = declarations.select { |d| %w[submitted eligible payable ineligible].include?(d.state) }

          expect(described_class.voidable).to match_array(voidable_declarations)
        end
      end

      describe ".changeable" do
        it "returns declarations with changeable states" do
          changeable_declarations = declarations.select { |d| %w[eligible submitted].include?(d.state) }

          expect(described_class.changeable).to match_array(changeable_declarations)
        end
      end

      describe ".billable_or_changeable" do
        it "returns declarations with either billable or changeable states" do
          states = %w[submitted eligible payable paid]
          billable_or_changeable = declarations.select { |d| states.include?(d.state) }

          expect(described_class.billable_or_changeable).to match_array(billable_or_changeable)
        end
      end

      describe ".billable_or_voidable" do
        it "returns declarations with either billable or voidable states" do
          states = %w[submitted eligible payable paid ineligible]
          billable_or_voidable = declarations.select { |d| states.include?(d.state) }

          expect(described_class.billable_or_voidable).to match_array(billable_or_voidable)
        end
      end
    end

    describe ".with_lead_provider" do
      let(:lead_provider) { declaration.lead_provider }
      let(:declaration) { create(:declaration) }

      before { create(:declaration, lead_provider: LeadProvider.where.not(id: lead_provider.id).first) }

      it { expect(described_class.with_lead_provider(lead_provider)).to contain_exactly(declaration) }
    end

    describe ".completed" do
      let(:completed_declaration) { create(:declaration, :completed) }

      before do
        described_class.declaration_types.keys.excluding("completed").each do |declaration_type|
          create(:declaration, declaration_type:)
        end
      end

      it { expect(described_class.completed).to contain_exactly(completed_declaration) }
    end

    describe ".with_course_identifier" do
      let(:course_identifier) { declaration.application.course.identifier }
      let(:declaration) { create(:declaration) }

      before do
        Course::IDENTIFIERS.excluding(course_identifier).each do |identifier|
          create(:declaration, course: Course.find_by(identifier:))
        end
      end

      it { expect(described_class.with_course_identifier(course_identifier)).to contain_exactly(declaration) }
    end
  end

  describe "#duplicate_declarations" do
    let(:cohort) { create(:cohort, :current) }
    let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
    let(:course) { create(:course, :senior_leadership, course_group:) }
    let(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
    let(:application) { create(:application, :accepted, cohort:, course:) }
    let(:participant) { application.user }
    let!(:declaration) { create(:declaration, application:) }

    context "when a user exists with the same TRN" do
      let(:other_user) { create(:user, trn: participant.trn) }

      context "when declarations have been made for a user with the same trn" do
        context "when declarations have been made for the same course" do
          let(:other_application) { create(:application, :accepted, cohort:, course:, user: other_user) }
          let!(:other_declaration) { create(:declaration, application: other_application) }

          it "returns those declarations" do
            expect(declaration.duplicate_declarations).to eq([other_declaration])
          end
        end

        context "when declarations have been made for a different course" do
          before do
            course = create(:course, :early_headship_coaching_offer, course_group:)
            other_application = create(:application, :accepted, course:, cohort:, user: other_user)
            create(:declaration, application: other_application)
          end

          it "returns no declarations" do
            expect(declaration.duplicate_declarations).to be_empty
          end
        end
      end

      context "when no declaration has been made for a user with the same trn" do
        it "returns no declarations" do
          expect(declaration.duplicate_declarations).to be_empty
        end
      end
    end

    context "when a declaration has been superseded by another" do
      before { create(:declaration, application:, superseded_by: declaration) }

      it "returns no declarations" do
        expect(declaration.duplicate_declarations).to be_empty
      end
    end

    context "when a declaration has a different type" do
      before { create(:declaration, application:, declaration_type: :completed) }

      it "returns no declarations" do
        expect(declaration.duplicate_declarations).to be_empty
      end
    end

    context "when a declaration has a not billable/submitted state" do
      before { create(:declaration, application:, state: :clawed_back) }

      it "returns no declarations" do
        expect(declaration.duplicate_declarations).to be_empty
      end
    end

    context "when declarations have been made for a different course" do
      before do
        course = create(:course, :early_headship_coaching_offer, course_group:)
        other_application = create(:application, :accepted, course:, cohort:, user: participant)
        create(:declaration, application: other_application)
      end

      it "returns no declarations" do
        expect(declaration.duplicate_declarations).to be_empty
      end
    end
  end
end
