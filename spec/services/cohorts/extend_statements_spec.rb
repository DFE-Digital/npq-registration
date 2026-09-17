require "rails_helper"

RSpec.describe Cohorts::ExtendStatements, type: :model do
  subject(:service) { described_class.new(cohort:, extension_date:) }

  let(:cohort) { nil }
  let(:extension_date) { nil }

  describe "attributes" do
    it { is_expected.to respond_to :cohort }
    it { is_expected.to respond_to :extension_date }
  end

  describe "validations" do
    let(:cohort) { create(:cohort, :current, :with_statement) }
    let(:extension_date) { 2.years.from_now }

    it { is_expected.to validate_presence_of :cohort }
    it { is_expected.to validate_presence_of(:extension_date).with_message("Enter a date to extend statements to") }

    context "without existing statements" do
      let(:cohort) { create(:cohort, :current) }

      it { is_expected.to have_error :extension_date, :no_existing_statements, "There are no existing statements to copy for this Cohort" }
    end

    context "with a past date" do
      let(:extension_date) { Time.zone.today }

      it { is_expected.to have_error :extension_date, :in_past, "The date to extend statements forward to must be in the future" }
    end

    context "with an extension date before the last statements date" do
      let(:extension_date) { cohort.statements.last.payment_date - 1.month }

      it { is_expected.to have_error :extension_date, :before_last_statement, "The date to extend statements forward to must be after the Cohorts last statement" }
    end

    context "with extension date and cohort" do
      subject { described_class.new(cohort:, extension_date:) }

      it { is_expected.to be_valid }
    end
  end

  describe "statement methods" do
    let(:cohort) { create(:cohort, :current) }
    let(:lead_providers) { create_list(:lead_provider, 3) }

    let :statements do
      lead_providers.flat_map do |lead_provider|
        (1..3).to_a.reverse.map do
          create(:statement, cohort:, lead_provider:, for_date: it.months.from_now)
        end
      end
    end

    describe "#last_statement" do
      it { is_expected.to have_attributes last_statement: statements[6] }
    end

    describe "#ending_statements" do
      subject(:ending_statements) { service.ending_statements.to_a }

      before { statements }

      it "identifies the correct statements" do
        expect(ending_statements).to contain_exactly(statements[0], statements[3], statements[6])
      end

      it "orders by lead provider names" do
        expect(ending_statements.map(&:lead_provider)).to eq lead_providers.sort_by(&:name)
      end
    end
  end

  describe "#schedule_change" do
    subject(:schedule) { service.schedule_change }

    before { allow(Cohorts::ExtendStatementsJob).to receive(:perform_later) }

    context "with valid change" do
      let(:cohort) { create(:cohort, :current, :with_statement) }
      let(:extension_date) { 3.months.from_now.to_date }

      it "schedules the job" do
        expect(schedule).to be true

        expect(Cohorts::ExtendStatementsJob)
          .to have_received(:perform_later).with(cohort_id: cohort.id, extension_date:)
      end
    end

    context "with invalid change" do
      it "does not schedule the job" do
        expect(schedule).to be false

        expect(Cohorts::ExtendStatementsJob).not_to have_received(:perform_later)
      end
    end
  end

  describe "#extend_statements!" do
    let(:cohort) { create(:cohort, :current) }
    let(:existing_date) { 1.year.from_now.beginning_of_year + 1.month }
    let(:extension_date) { existing_date + 3.months }
    let(:lead_providers) { LeadProvider.limit(2).order(:id).to_a }
    let(:courses) { Course.limit(2).order(:id).to_a }

    let :statements do
      lead_providers.map do |lead_provider|
        create(:statement, cohort:, lead_provider:, for_date: existing_date)
      end
    end

    let :contracts do
      statements.flat_map do |statement|
        courses.map do |course|
          create(:contract, course:, statement:)
        end
      end
    end

    # { lead_provider_id => [course_id, template_id] }
    let :template_ids do
      contracts
        .group_by { it.statement.lead_provider_id }
        .transform_values { it.pluck(:course_id, :contract_template_id) }
    end

    describe "statement creation" do
      before { contracts && service.extend_statements! }

      it "statements are added for all LPs" do
        expect(cohort.statements.pluck(:lead_provider_id, :year, :month, :output_fee).sort)
          .to contain_exactly(
            [lead_providers[0].id, existing_date.year, 2, true],
            [lead_providers[0].id, existing_date.year, 3, false],
            [lead_providers[0].id, existing_date.year, 4, false],
            [lead_providers[0].id, existing_date.year, 5, true],
            [lead_providers[1].id, existing_date.year, 2, true],
            [lead_providers[1].id, existing_date.year, 3, false],
            [lead_providers[1].id, existing_date.year, 4, false],
            [lead_providers[1].id, existing_date.year, 5, true],
          )
      end

      it "adds a contract for each course to each new statement" do
        contracts_per_statement = Contract
          .joins(:statement)
          .where(statements: { cohort: })
          .group(:statement_id)
          .count

        expect(contracts_per_statement.values).to all eq(2)
      end

      it "adds each course to each statement" do
        statements_per_course = Contract
          .joins(:statement)
          .where(statements: { cohort: })
          .group(:course_id)
          .count

        expect(statements_per_course.values).to all eq(8) # 4 statements for 2 lead providers
      end

      it "reuses existing contract templates" do
        template_counts = ContractTemplate
          .joins(contracts: :statement)
          .where(statements: { cohort: })
          .group(:contract_template_id)
          .count

        expect(ContractTemplate.count).to eq(4) # 2 courses for 2 lead providers
        expect(template_counts.length).to eq(4) # templates used by cohort statements
        expect(template_counts.values).to all eq(4) # Mar, Apr, May Jun statements
      end

      context "with multiple cohorts" do
        let(:second_cohort) { create(:cohort, :previous) }

        let :statements do
          lead_providers.map do |lead_provider|
            create(:statement, cohort:, lead_provider:, for_date: existing_date)
            create(:statement, cohort: second_cohort, lead_provider:, for_date: existing_date)
          end
        end

        it "only creates new statements in chosen cohort" do
          expect(cohort.statements.count).to eq(8)
          expect(second_cohort.statements.count).to eq(2)
        end
      end

      context "with different ending statements per lead provider" do
        let :statements do
          [
            create(:statement, cohort:, lead_provider: lead_providers[0], for_date: existing_date),
            create(:statement, cohort:, lead_provider: lead_providers[1], output_fee: false, for_date: existing_date),
            create(:statement, cohort:, lead_provider: lead_providers[1], for_date: existing_date + 1.month),
          ]
        end

        it "creates expected statements" do
          lp1 = cohort
            .statements
            .where(lead_provider: lead_providers[0])
            .order(:month)
            .pluck(:month, :output_fee)

          lp2 = cohort
            .statements
            .where(lead_provider: lead_providers[1])
            .order(:month)
            .pluck(:month, :output_fee)

          expect(lp1).to contain_exactly([2, true], [3, false], [4, false], [5, true])
          expect(lp2).to contain_exactly([2, false], [3, true], [4, false], [5, true])
        end
      end
    end

    describe "transaction and locking" do
      before do
        allow(Contract).to receive(:create!).and_call_original
        allow(Statement).to receive(:with_advisory_lock!)
          .with("lock-cohort-#{cohort.identifier}")
          .and_call_original

        allow(Contract).to receive(:create!)
          .with(course_id: courses[1].id,
                contract_template_id: contracts[-1].contract_template_id,
                statement: anything)
          .and_raise(ActiveRecord::Rollback)
      end

      let(:lead_providers) { LeadProvider.order(:id).limit(2).to_a }
      let(:courses) { Course.order(:id).limit(2).to_a }

      let :statements do
        lead_providers.map do |lead_provider|
          create(:statement, cohort:, lead_provider:, for_date: existing_date)
        end
      end

      let :contracts do
        statements.flat_map do |statement|
          courses.map do |course|
            create(:contract, course:, statement:)
          end
        end
      end

      it "does not change any data" do
        expect { service.extend_statements! }
          .to not_change(Statement, :count)
                .and(not_change(Contract, :count))
                .and(not_change(ContractTemplate, :count))

        expect(Statement).to have_received(:with_advisory_lock!)
          .with("lock-cohort-#{cohort.identifier}")
      end
    end
  end
end
