require "rails_helper"

RSpec.describe Statements::ChangeOutputFeeJob, type: :job do
  subject(:perform) { job.perform_now }

  let(:job) { described_class.new(statement_id:, output_fee:) }
  let(:output_fee) { true }

  context "with unknown statement" do
    let(:statement_id) { 19 }

    it { expect { perform }.to raise_exception(ActiveRecord::RecordNotFound) }
  end

  context "with known statement" do
    before do
      allow(Statements::ChangeOutputFee)
        .to receive(:new).with(**service_args).and_return(service)

      perform
    end

    let :service do
      instance_double(Statements::ChangeOutputFee,
                      change_statement_and_reconcile!: true)
    end

    let(:service_args) { { statement:, output_fee: } }
    let(:statement_id) { statement.id }
    let(:statement) { create(:statement, :open, for_date: 30.days.from_now) }

    it { expect(service).to have_received(:change_statement_and_reconcile!) }

    context "with allow_payable_statement_changes" do
      let(:service_args) { { statement:, output_fee:, allow_payable_statement_changes: true } }

      let :job do
        described_class.new(statement_id:, output_fee:, allow_payable_statement_changes: true)
      end

      it { expect(service).to have_received(:change_statement_and_reconcile!) }
    end
  end
end
