require "rails_helper"

RSpec.describe Statements::ChangeOutputFeeJob, type: :job do
  subject(:perform) { job.perform_now }

  let(:job) { described_class.new(statement_id:, output_fee:) }
  let(:output_fee) { true }

  before do
    allow_any_instance_of(Statements::ChangeOutputFee)
      .to receive(:change_statement_and_reconcile!)
            .and_return(true)
  end

  context "with unknown statement" do
    let(:statement_id) { 19 }

    it { expect { perform }.to raise_exception(ActiveRecord::RecordNotFound) }
  end

  context "with known statement" do
    let(:statement_id) { create(:statement, :open, for_date: 30.days.from_now).id }

    it { is_expected.to be true }
  end
end
