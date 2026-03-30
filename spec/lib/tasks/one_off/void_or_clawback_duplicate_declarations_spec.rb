require "rails_helper"

RSpec.describe "one_off:void_or_clawback_duplicate_declarations" do
  subject :run_task do
    Rake::Task["one_off:void_or_clawback_duplicate_declarations"].invoke(dry_run)
  end

  let(:lead_provider) { create(:lead_provider) }
  let(:cohort) { create(:cohort, :current) }
  let(:application) { create(:application, :accepted, cohort:, lead_provider:) }
  let(:declaration) { create(:declaration, :paid, application:, lead_provider:) }
  let(:duplicate_declaration) { create(:declaration, :paid, application:, lead_provider:) }
  let(:not_paid_declaration) { create(:declaration, :payable, application:, lead_provider:) }
  let(:other_cohort) { create(:cohort, :next) }
  let(:other_cohort_application) { create(:application, :accepted, cohort: other_cohort, lead_provider:) }
  let(:other_cohort_declaration) { create(:declaration, :paid, application: other_cohort_application, cohort: other_cohort, lead_provider:) }
  let(:other_cohort_duplicate_declaration) { create(:declaration, :paid, application: other_cohort_application, cohort: other_cohort, lead_provider:) }
  let(:other_cohort_not_paid_declaration) { create(:declaration, :payable, application: other_cohort_application, cohort: other_cohort, lead_provider:) }
  let(:application_with_no_duplicate_declarations) { create(:application, :accepted, cohort:, lead_provider:) }
  let(:non_duplcate_declaration) { create(:declaration, :paid, application: application_with_no_duplicate_declarations, cohort: cohort, lead_provider:) }
  let(:non_duplcate_declaration_retained) { create(:declaration, :paid, application: application_with_no_duplicate_declarations, cohort: cohort, lead_provider:, declaration_type: "retained-1") }
  let(:non_duplcate_declaration_completed) { create(:declaration, :paid, :completed, application: application_with_no_duplicate_declarations, cohort: cohort, lead_provider:) }
  let(:statement) { create(:statement, :next_output_fee, cohort:, lead_provider:) }
  let(:other_statement) { create(:statement, :next_output_fee, cohort: other_cohort, lead_provider:) }
  let(:submitted_declaration) { create(:declaration, :submitted, application:, lead_provider:) }
  let(:duplicate_submitted_declaration) { create(:declaration, :submitted, application:, lead_provider:) }
  let(:non_duplicate_submitted_declaration) { create(:declaration, :submitted, application: application_with_no_duplicate_declarations, cohort:, lead_provider:) }

  let(:paid_declarations) do
    [
      declaration,
      duplicate_declaration,
      other_cohort_declaration,
      other_cohort_duplicate_declaration,
      non_duplcate_declaration,
      non_duplcate_declaration_retained,
      non_duplcate_declaration_completed,
    ]
  end

  let(:payable_declarations) do
    [
      not_paid_declaration,
      other_cohort_not_paid_declaration,
    ]
  end

  let(:submitted_delcarations) do
    [
      submitted_declaration,
      duplicate_submitted_declaration,
      non_duplicate_submitted_declaration,
    ]
  end

  before do
    paid_declarations
    payable_declarations
    submitted_delcarations
    statement
    other_statement
  end

  after { Rake::Task["one_off:void_or_clawback_duplicate_declarations"].reenable }

  context "when dry run is false" do
    let(:dry_run) { "false" }

    it "claws back the duplicate paid declarations" do
      run_task
      expect(duplicate_declaration.reload.state).to eq "awaiting_clawback"
      expect(other_cohort_duplicate_declaration.reload.state).to eq "awaiting_clawback"
    end

    it "voids the duplicate submitted declarations" do
      run_task
      expect(duplicate_submitted_declaration.reload.state).to eq "voided"
    end

    it "attaches the duplicate paid declarations to a statement" do
      run_task
      expect(statement.declarations).to contain_exactly(duplicate_declaration)
      expect(other_statement.declarations).to contain_exactly(other_cohort_duplicate_declaration)
    end

    it "does not void declarations that are not duplicates" do
      run_task
      expect(declaration.reload.state).to eq "paid"
      expect(other_cohort_declaration.reload.state).to eq "paid"
      expect(non_duplcate_declaration.reload.state).to eq "paid"
      expect(non_duplcate_declaration_retained.reload.state).to eq "paid"
      expect(non_duplcate_declaration_completed.reload.state).to eq "paid"
      expect(submitted_declaration.reload.state).to eq "submitted"
      expect(non_duplicate_submitted_declaration.reload.state).to eq "submitted"
    end

    context "when there is a validation error on the declaration" do
      before do
        # simulate error by removing the required output fee statement
        other_statement.destroy
      end

      it "raises an error and rolls back the transaction so no declarations are voided" do
        run_task
        paid_declarations.each { |declaration| expect(declaration.reload.state).to eq "paid" }
        payable_declarations.each { |declaration| expect(declaration.reload.state).to eq "payable" }
        submitted_delcarations.each { |declaration| expect(declaration.reload.state).to eq "submitted" }
      end
    end
  end

  context "when dry run is true" do
    let(:dry_run) { "true" }

    it "does not void any declarations" do
      run_task
      paid_declarations.each { |declaration| expect(declaration.reload.state).to eq "paid" }
      payable_declarations.each { |declaration| expect(declaration.reload.state).to eq "payable" }
      submitted_delcarations.each { |declaration| expect(declaration.reload.state).to eq "submitted" }
    end

    it "does not attach any declarations to a statement" do
      run_task
      expect(statement.declarations).to be_empty
      expect(other_statement.declarations).to be_empty
    end
  end
end
