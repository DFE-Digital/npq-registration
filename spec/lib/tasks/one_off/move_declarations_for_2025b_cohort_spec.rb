require "rails_helper"

RSpec.describe "one_off:move_declarations_for_2025b_cohort" do
  subject :run_task do
    Rake::Task["one_off:move_declarations_for_2025b_cohort"].invoke(dry_run)
  end

  let(:cohort_2025a) { create(:cohort, start_year: 2025, suffix: "a") }
  let(:cohort_2025b) { create(:cohort, start_year: 2025, suffix: "b") }
  let(:lead_provider_1) { create(:lead_provider) }
  let(:lead_provider_2) { create(:lead_provider) }
  let(:declaration_created_at) { Time.zone.parse("2026-01-23 12:00") }

  let(:lead_provider_1_statement_sept_2026) do
    create(:statement,
           :open, :next_output_fee, cohort: cohort_2025b, lead_provider: lead_provider_1, month: 9, year: 2026)
  end

  let(:lead_provider_1_statement_feb_2026) do
    create(:statement,
           :open, :next_output_fee, cohort: cohort_2025b, lead_provider: lead_provider_1, month: 2, year: 2026)
  end

  let(:lead_provider_2_statement_sept_2026) do
    create(:statement,
           :open, :next_output_fee, cohort: cohort_2025b, lead_provider: lead_provider_2, month: 9, year: 2026)
  end

  let(:lead_provider_2_statement_feb_2026) do
    create(:statement,
           :open, :next_output_fee, cohort: cohort_2025b, lead_provider: lead_provider_2, month: 2, year: 2026)
  end

  let(:other_statement) do
    create(:statement,
           :open, cohort: cohort_2025b, lead_provider: lead_provider_1, month: 6, year: 2026)
  end

  let(:statement_in_other_cohort) do
    create(:statement,
           :open, cohort: cohort_2025a, lead_provider: lead_provider_1, month: 9, year: 2026)
  end

  let(:lead_provider_1_declaration) do
    create(:declaration,
           :eligible,
           created_at: declaration_created_at,
           cohort: cohort_2025b,
           lead_provider: lead_provider_1,
           statement: lead_provider_1_statement_sept_2026)
  end

  let(:lead_provider_1_voided_declaration) do
    create(:declaration,
           :voided,
           created_at: declaration_created_at,
           cohort: cohort_2025b,
           lead_provider: lead_provider_1,
           statement: lead_provider_1_statement_sept_2026)
  end

  let(:lead_provider_2_declaration) do
    create(:declaration,
           :eligible,
           created_at: declaration_created_at,
           cohort: cohort_2025b,
           lead_provider: lead_provider_2,
           statement: lead_provider_2_statement_sept_2026)
  end

  before do
    lead_provider_1_statement_feb_2026
    lead_provider_2_statement_feb_2026
  end

  after { Rake::Task["one_off:move_declarations_for_2025b_cohort"].reenable }

  context "when real run" do
    let(:dry_run) { "false" }

    context "when the declarations were created before 24th Jan 2026" do
      before do
        lead_provider_1_declaration
        lead_provider_1_voided_declaration
        lead_provider_2_declaration
      end

      it "moves the declarations from the Sept 2026 statement to the Feb 2026 statement" do
        subject

        expect(lead_provider_1_declaration.statements).to include(lead_provider_1_statement_feb_2026)
        expect(lead_provider_1_declaration.statements).not_to include(lead_provider_1_statement_sept_2026)

        expect(lead_provider_2_declaration.statements).to include(lead_provider_2_statement_feb_2026)
        expect(lead_provider_2_declaration.statements).not_to include(lead_provider_2_statement_sept_2026)
      end

      it "marks the declarations as payable" do
        subject

        expect(lead_provider_1_declaration.reload).to be_payable
        expect(lead_provider_2_declaration.reload).to be_payable
      end

      it "does not mark voided declarations as payable" do
        subject

        expect(lead_provider_1_voided_declaration.reload).to be_voided
      end
    end

    context "when the declarations were created after 24th Jan 2026" do
      let(:declaration_created_at) { Time.zone.parse("2026-01-25 12:00") }

      before do
        lead_provider_1_declaration
        lead_provider_2_declaration
      end

      it "does not move the declarations" do
        subject

        expect(lead_provider_1_declaration.statements).to include(lead_provider_1_statement_sept_2026)
        expect(lead_provider_1_declaration.statements).not_to include(lead_provider_1_statement_feb_2026)

        expect(lead_provider_2_declaration.statements).to include(lead_provider_2_statement_sept_2026)
        expect(lead_provider_2_declaration.statements).not_to include(lead_provider_2_statement_feb_2026)
      end

      it "does not mark the declarations as payable" do
        subject

        expect(lead_provider_1_declaration.reload).to be_eligible
        expect(lead_provider_2_declaration.reload).to be_eligible
      end
    end

    context "when the declaration is not on the Sept 2026 statement" do
      let(:declaration_on_other_statement) do
        create(:declaration,
               :eligible,
               created_at: declaration_created_at,
               cohort: cohort_2025b,
               lead_provider: lead_provider_1,
               statement: other_statement)
      end

      before { declaration_on_other_statement }

      it "does not move the declaration" do
        subject

        expect(declaration_on_other_statement.statements).to include(other_statement)
      end

      it "does not mark the declaration as payable" do
        subject

        expect(declaration_on_other_statement.reload).to be_eligible
      end
    end

    context "when the declaration is in another cohort" do
      let(:declaration_in_other_cohort) do
        create(:declaration,
               :eligible,
               created_at: declaration_created_at,
               cohort: cohort_2025a,
               lead_provider: lead_provider_1,
               statement: statement_in_other_cohort)
      end

      before { declaration_in_other_cohort }

      it "does not move the declaration" do
        subject

        expect(declaration_in_other_cohort.statements).to include(statement_in_other_cohort)
      end

      it "does not mark the declaration as payable" do
        subject

        expect(declaration_in_other_cohort.reload).to be_eligible
      end
    end
  end

  context "when dry run" do
    let(:dry_run) { nil }

    context "when the declarations were created before 24th Jan 2026" do
      before do
        lead_provider_1_declaration
        lead_provider_2_declaration
      end

      it "does not move the declarations" do
        subject

        expect(lead_provider_1_declaration.statements).to include(lead_provider_1_statement_sept_2026)
        expect(lead_provider_1_declaration.statements).not_to include(lead_provider_1_statement_feb_2026)

        expect(lead_provider_2_declaration.statements).to include(lead_provider_2_statement_sept_2026)
        expect(lead_provider_2_declaration.statements).not_to include(lead_provider_2_statement_feb_2026)
      end

      it "does not mark the declarations as payable" do
        subject

        expect(lead_provider_1_declaration.reload).to be_eligible
        expect(lead_provider_2_declaration.reload).to be_eligible
      end
    end
  end
end
