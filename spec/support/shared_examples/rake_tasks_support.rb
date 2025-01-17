# frozen_string_literal: true

RSpec.shared_examples "exiting with error code 1" do
  it "exits with error code 1" do
    expect { run_task }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
  end
end

RSpec.shared_examples "passing dry_run to the service" do
  context "when dry run false" do
    let(:dry_run) { "false" }

    it "calls the service with dry_run: false" do
      expect(service_double).to receive(:call).with(dry_run: false)
      run_task
    end
  end

  context "when dry run true" do
    let(:dry_run) { "true" }

    it "calls the service with dry_run: true" do
      expect(service_double).to receive(:call).with(dry_run: true)
      run_task
    end
  end

  context "when dry run not specified" do
    let(:dry_run) { nil }

    it "calls the service with dry_run: true" do
      expect(service_double).to receive(:call).with(dry_run: true)
      run_task
    end
  end
end
