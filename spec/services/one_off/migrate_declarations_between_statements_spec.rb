require "rails_helper"

RSpec.describe OneOff::MigrateDeclarationsBetweenStatements, type: :model do
  let(:logged_output) { [] }
  let(:from_statement_updates) { {} }
  let(:to_statement_updates) { {} }
  let(:lead_provider) { create(:lead_provider) }
  let(:from_statement) { create(:statement, month: 4, year: 2023, lead_provider:, cohort:, output_fee: true) }
  let(:to_statement) { create(:statement, :next_output_fee, month: 5, year: 2023, lead_provider:, cohort:, payment_date: 1.day.from_now) }
  let(:from_month) { from_statement.month }
  let(:from_year) { from_statement.year }
  let(:to_month) { to_statement.month }
  let(:to_year) { to_statement.year }
  let(:cohort) { create(:cohort, :current) }
  let(:course) { create(:course, identifier: "npq-senior-leadership") }
  let(:restrict_to_lead_providers) { nil }
  let(:restrict_to_declaration_types) { nil }
  let(:restrict_to_declaration_states) { nil }
  let(:restrict_to_course_identifiers) { nil }

  let(:instance) do
    described_class.new(
      cohort:,
      from_month:,
      from_year:,
      to_month:,
      to_year:,
      from_statement_updates:,
      to_statement_updates:,
      restrict_to_lead_providers:,
      restrict_to_declaration_types:,
      restrict_to_declaration_states:,
      restrict_to_course_identifiers:,
    )
  end

  before { allow(Rails.logger).to receive(:info) { |msg| logged_output << msg } }

  describe "#migrate" do
    let(:dry_run) { false }

    subject(:migrate) { instance.migrate(dry_run:) }

    context "when there are declarations" do
      before { declaration && declaration2 && to_statement2 }

      let(:declaration) { create(:declaration, :payable, cohort:, lead_provider:, course:, statement: from_statement) }
      let(:course2) { create(:course, identifier: "npq-leading-behaviour-culture") }
      let(:declaration2) { create(:declaration, :eligible, cohort:, declaration_type: :"retained-1", course: course2, statement: from_statement2, lead_provider: lead_provider2) }
      let(:lead_provider2) { create(:lead_provider) }
      let(:from_statement2) { create(:statement, month: from_statement.month, year: from_statement.year, cohort:, output_fee: true, lead_provider: lead_provider2) }
      let(:to_statement2) { create(:statement, :next_output_fee, month: to_statement.month, year: to_statement.year, lead_provider: lead_provider2, cohort:) }

      it "migrates them to the new statement" do
        migrate

        expect(declaration.reload.statements).to all eq(to_statement)
        expect(declaration2.reload.statements).to all eq(to_statement2)
      end

      it "records information" do
        migrate

        expect(logged_output)
          .to include("Migrating declarations from #{from_year}-#{from_month} to #{to_year}-#{to_month} for 2 providers")
                .and include("Migrating 1 declarations for #{lead_provider.name} - from statement #{from_statement.id} to statement #{to_statement.id}")
                .and include("Migrating 1 declarations for #{lead_provider2.name} - from statement #{from_statement2.id} to statement #{to_statement2.id}")
      end

      context "when restrict_to_lead_providers is provided" do
        let(:restrict_to_lead_providers) { [lead_provider] }

        it "migrates only the declarations for the given lead provider to the new statement" do
          migrate

          expect(declaration.statement_items.map(&:statement)).to all eq(to_statement)
          expect(declaration2.statement_items.map(&:statement)).to all eq(from_statement2)
        end

        it "records information" do
          migrate

          expect(logged_output)
            .to include("Migrating declarations from #{from_year}-#{from_month} to #{to_year}-#{to_month} for 1 providers")
                .and include("Migrating 1 declarations for #{lead_provider.name} - from statement #{from_statement.id} to statement #{to_statement.id}")
        end
      end

      context "when restrict_to_declaration_types is provided" do
        let(:restrict_to_declaration_types) { [:started] }

        it "migrates only the declarations with the given declaration type" do
          migrate

          expect(declaration.statement_items.map(&:statement)).to all eq(to_statement)
          expect(declaration2.statement_items.map(&:statement)).to all eq(from_statement2)
        end

        it "records information" do
          migrate

          expect(logged_output)
            .to include("Migrating declarations from #{from_year}-#{from_month} to #{to_year}-#{to_month} for 2 providers")
                .and include("Migrating 1 declarations for #{lead_provider.name} - from statement #{from_statement.id} to statement #{to_statement.id}")
                .and include("Migrating 0 declarations for #{lead_provider2.name} - from statement #{from_statement2.id} to statement #{to_statement2.id}")
        end

        context "when restrict_to_declaration_types contains a string" do
          let(:restrict_to_declaration_types) { %w[retained-1] }

          it "migrates only the declarations with the given declaration type" do
            migrate

            expect(declaration2.statement_items.map(&:statement)).to all eq(to_statement2)
            expect(declaration.statement_items.map(&:statement)).to all eq(from_statement)
          end
        end
      end

      context "when restrict_to_declaration_states is provided" do
        let(:restrict_to_declaration_states) { [:eligible] }

        it "migrates only the declarations with the given declaration type" do
          migrate

          expect(declaration.statement_items.map(&:statement)).to all eq(from_statement)
          expect(declaration2.statement_items.map(&:statement)).to all eq(to_statement2)
        end

        it "records information" do
          migrate

          expect(logged_output)
            .to include("Migrating declarations from #{from_year}-#{from_month} to #{to_year}-#{to_month} for 2 providers")
                .and include("Migrating 0 declarations for #{lead_provider.name} - from statement #{from_statement.id} to statement #{to_statement.id}")
                .and include("Migrating 1 declarations for #{lead_provider2.name} - from statement #{from_statement2.id} to statement #{to_statement2.id}")
        end

        context "when restrict_to_declaration_types contains a string" do
          let(:restrict_to_declaration_states) { %w[eligible] }

          it "migrates only the declarations with the given declaration type" do
            migrate

            expect(declaration.statement_items.map(&:statement)).to all eq(from_statement)
            expect(declaration2.statement_items.map(&:statement)).to all eq(to_statement2)
          end
        end
      end

      context "when from_statement_updates are provided" do
        let(:from_statement_updates) { { output_fee: false } }

        it "updates the to statements" do
          migrate

          expect(from_statement.reload).to have_attributes(from_statement_updates)
          expect(logged_output).to include("Statement #{from_statement.year}-#{from_statement.month} for #{from_statement.lead_provider.name} updated from: {\"output_fee\" => true} to {\"output_fee\" => false}")
        end
      end

      context "when to_statement_updates are provided" do
        let!(:old_deadline_date) { to_statement.deadline_date }
        let!(:old_payment_date) { to_statement.payment_date }
        let(:new_deadline_date) { 5.days.from_now.to_date }
        let(:new_payment_date) { 2.days.from_now.to_date }
        let(:to_statement_updates) { { deadline_date: new_deadline_date, payment_date: new_payment_date } }

        it "updates the to statements" do
          migrate

          expect(to_statement.reload).to have_attributes(to_statement_updates)
          expect(logged_output).to include("Statement #{to_statement.year}-#{to_statement.month} for #{to_statement.lead_provider.name} " \
                                           "updated from: {\"deadline_date\" => #{old_deadline_date.inspect}, \"payment_date\" => #{old_payment_date.inspect}} " \
                                           "to {\"deadline_date\" => #{new_deadline_date.inspect}, \"payment_date\" => #{new_payment_date.inspect}}")
        end
      end

      context "when dry_run is true" do
        let(:dry_run) { true }

        it "does not make any changes, but logs out as if it does" do
          expect { migrate }
            .not_to(change { declaration.statement_items.first.reload.statement })

          expect(logged_output)
            .to include("~~~ DRY RUN ~~~")
                  .and include("Migrating declarations from #{from_year}-#{from_month} to #{to_year}-#{to_month} for 2 providers")
                  .and include("Migrating 1 declarations for #{lead_provider.name} - from statement #{from_statement.id} to statement #{to_statement.id}")
                  .and include("Migrating 1 declarations for #{lead_provider2.name} - from statement #{from_statement2.id} to statement #{to_statement2.id}")
        end
      end

      context "when restrict_to_course_identifiers is provided" do
        let(:restrict_to_course_identifiers) { [declaration2.course_identifier] }

        it "migrates only the declarations with the given course identifier" do
          migrate

          expect(declaration.statement_items.map(&:statement)).to all eq(from_statement)
          expect(declaration2.statement_items.map(&:statement)).to all eq(to_statement2)
        end

        it "records information" do
          migrate

          expect(logged_output)
            .to include("Migrating declarations from #{from_year}-#{from_month} to #{to_year}-#{to_month} for 2 providers")
                .and include("Migrating 0 declarations for #{lead_provider.name} - from statement #{from_statement.id} to statement #{to_statement.id}")
                .and include("Migrating 1 declarations for #{lead_provider2.name} - from statement #{from_statement2.id} to statement #{to_statement2.id}")
        end
      end
    end

    context "when migrating to a payable statement" do
      before { declaration }

      let(:to_statement) { create(:statement, :payable, :next_output_fee, month: 5, year: 2023, lead_provider:, cohort:) }
      let(:declaration) { create(:declaration, :eligible, cohort:, lead_provider:, course:, statement: from_statement) }

      it "migrates eligible declarations to the new statement and makes them payable" do
        migrate

        declaration.reload

        expect(declaration.statement_items.map(&:statement)).to all eq(to_statement)
        expect(declaration).to be_payable
      end

      it "records information" do
        migrate

        expect(logged_output)
          .to include("Migrating declarations from #{from_year}-#{from_month} to #{to_year}-#{to_month} for 1 providers")
              .and include("Migrating 1 declarations for #{lead_provider.name} - from statement #{from_statement.id} to statement #{to_statement.id}")
              .and include("Marking 1 eligible declarations as payable for #{to_year}-#{to_month} statement: #{to_statement.id}")
      end

      context "when there are declarations awaiting_clawback" do
        let :declaration do
          paid_statement =
            create(:statement, :paid, month: 3, year: 2023, lead_provider:, cohort:, output_fee: true)

          create(:declaration, :awaiting_clawback, cohort:, lead_provider:, course:, statement: from_statement, paid_statement:)
        end

        it "migrates them, but does not make them payable" do
          migrate

          declaration.reload

          migrated_statement_item = declaration.statement_items.find(&:awaiting_clawback?)
          expect(migrated_statement_item.statement).to eq(to_statement)
          expect(declaration).to be_awaiting_clawback
          expect(logged_output).not_to include(/eligible declarations as payable/)
        end
      end

      context "when there are declarations are already payable" do
        let(:declaration) { create(:declaration, :payable, cohort:, lead_provider:, course:, statement: from_statement) }

        it "migrates them, but does not attempt to make them payable" do
          migrate

          declaration.reload

          expect(declaration.statement_items.map(&:statement)).to all(eq(to_statement))
          expect(declaration).to be_payable
          expect(logged_output).not_to include(/eligible declarations as payable/)
        end
      end
    end

    context "when migrating to an open statement" do
      before { declaration }

      let(:from_statement) { create(:statement, :payable, month: 4, year: 2023, lead_provider:, cohort:, output_fee: true) }
      let(:to_statement) { create(:statement, :open, :next_output_fee, month: 5, year: 2023, lead_provider:, cohort:) }
      let(:declaration) { create(:declaration, :payable, cohort:, lead_provider:, course:, statement: from_statement) }

      it "migrates payable declarations to the new statement and makes them eligible" do
        migrate

        declaration.reload

        expect(declaration.statement_items.map(&:statement)).to all eq(to_statement)
        expect(declaration).to be_eligible
        expect(to_statement.statement_items.map(&:state)).to eq(%w[eligible])
      end

      it "records information" do
        migrate

        expect(logged_output).to include(
          "Migrating declarations from #{from_statement.year}-#{from_statement.month} to #{to_statement.year}-#{to_statement.month} for 1 providers",
          "Migrating 1 declarations for #{lead_provider.name} - from statement #{from_statement.id} to statement #{to_statement.id}",
          "Marking 1 payable declarations back as eligible for #{to_statement.year}-#{to_statement.month} statement: #{to_statement.id}",
        )
      end
    end

    context "when migrating from a paid statement" do
      before { declaration }

      let(:from_statement) { create(:statement, :paid, month: 4, year: 2023, lead_provider:, cohort:, output_fee: true) }
      let(:to_statement) { create(:statement, :open, :next_output_fee, month: 5, year: 2023, lead_provider:, cohort:) }
      let(:declaration) { create(:declaration, :paid, cohort:, lead_provider:, course:, statement: from_statement) }

      it "fails validation" do
        expect(migrate).to be false

        expect(instance.errors.full_messages)
          .to include("Cannot migrate from a paid statement")
      end
    end

    describe "integrity checks" do
      context "when there is a mismatch between the number of statements" do
        before { create(:statement, month: 4, year: 2023, cohort:, output_fee: true) }

        it "fails validation" do
          expect(instance.valid?).to be false

          expect(instance.errors.full_messages)
            .to include("There is a mismatch between to/from statements")
        end
      end

      context "when a to statement has a deadline date in the past" do
        before { to_statement.update!(deadline_date: 1.day.ago) }

        it "fails validation" do
          expect(instance.valid?).to be false

          expect(instance.errors.full_messages)
            .to include("To statements are not future dated")
        end

        context "with override_date_checks is set" do
          before { instance.override_date_checks = true }

          it "passes validation" do
            expect(instance.valid?).to be true
          end
        end
      end

      context "when attempting to migrate between statements on different cohorts" do
        let(:other_cohort) { create(:cohort, :previous) }

        before { from_statement.update!(cohort: other_cohort) }

        it "fails validation" do
          expect(instance.valid?).to be false

          expect(instance.errors.full_messages)
            .to include("There is a mismatch between to/from statements")
        end
      end

      context "when there are no statements found" do
        let(:from_month) { 13 }
        let(:to_month) { 13 }

        it "fails validation" do
          expect(instance.valid?).to be false

          expect(instance.errors.full_messages)
            .to include("No statements were found")
        end
      end
    end
  end
end
