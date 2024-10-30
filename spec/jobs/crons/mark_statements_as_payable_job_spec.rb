require "rails_helper"

RSpec.describe Crons::MarkStatementsAsPayableJob, type: :job do
  let(:application) { create(:application, :eligible_for_funded_place) }
  let(:lead_provider) { application.lead_provider }
  let(:statement) { create(:statement, :next_output_fee, lead_provider:) }

  before do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    declaration = create(:declaration, :submitted_or_eligible, lead_provider:, application:)
    create(:statement_item, :eligible, statement:, declaration:)
    voided_declaration = create(:declaration, :voided, lead_provider:)
    create(:statement_item, :voided, statement:, declaration: voided_declaration)
  end

  describe "#perform" do
    it "transitions eligible statement/declarations to payable", :aggregate_failures do
      expect {
        travel_to(statement.deadline_date + 1.day) do
          described_class.perform_now
          statement.reload
        end
      }.to change(statement.declarations.payable_state, :count).from(0).to(1)

      expect(statement.state).to eq("payable")
    end

    it "transitions statement items to payable" do
      expect {
        travel_to(statement.deadline_date + 1.day) do
          described_class.perform_now
          statement.reload
        end
      }.to change(statement.statement_items.where(state: "payable"), :count).from(0).to(1)
    end
  end

  describe "#perform_later" do
    it "enqueues the job exactly once" do
      expect { described_class.perform_later }.to have_enqueued_job(described_class).exactly(:once).on_queue("default")
    end
  end
end
