# frozen_string_literal: true

RSpec.shared_examples "exiting with error code 1" do
  it "exits with error code 1" do
    expect { run_task }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
  end
end
