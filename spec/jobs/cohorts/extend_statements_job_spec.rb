require "rails_helper"

RSpec.describe Cohorts::ExtendStatementsJob, type: :job do
  subject(:perform) { job.perform_now }

  let(:job) { described_class.new(cohort_id:, extension_date:) }
  let(:extension_date) { 1.year.from_now }

  context "with unknown cohort" do
    let(:cohort_id) { 190 }

    it { expect { perform }.to raise_exception(ActiveRecord::RecordNotFound) }
  end

  context "with known cohort" do
    before do
      allow(Cohorts::ExtendStatements)
        .to receive(:new).with(**service_args).and_return(service)

      perform
    end

    let :service do
      instance_double(Cohorts::ExtendStatements,
                      extend_statements!: true)
    end

    let(:service_args) { { cohort:, extension_date: } }
    let(:cohort_id) { cohort.id }
    let(:cohort) { create(:cohort, :current) }

    it { expect(service).to have_received(:extend_statements!) }
  end
end
