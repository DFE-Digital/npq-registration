require "rails_helper"

RSpec.describe "eyl_fundng_eligible_schools:update" do
  let(:csv_file) do
    tempfile <<~CSV
      gias_urn
      123456
      789012
      999999
    CSV
  end

  before do
    create(:school, urn: "123456", eyl_funding_eligible: false)
    create(:school, urn: "789012", eyl_funding_eligible: false)
    create(:school, urn: "345678", eyl_funding_eligible: false)

    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  after { Rake::Task["eyl_fundng_eligible_schools:update"].reenable }

  subject(:run_task) { Rake::Task["eyl_fundng_eligible_schools:update"].invoke(csv_file.path) }

  it "updates schools to be EYL funding eligible" do
    run_task

    expect(School.find_by(urn: "123456").eyl_funding_eligible).to be true
    expect(School.find_by(urn: "789012").eyl_funding_eligible).to be true
    expect(School.find_by(urn: "345678").eyl_funding_eligible).to be false
  end

  it "logs the correct number of updated records and errors" do
    run_task

    expect(Rails.logger).to have_received(:info).with("Updating schools from CSV file: #{csv_file.path}")
    expect(Rails.logger).to have_received(:info).with("Update finished")
    expect(Rails.logger).to have_received(:info).with("Updated Records: 2")
    expect(Rails.logger).to have_received(:info).with("Update Errors: 1")
    expect(Rails.logger).to have_received(:error).with("Failed to update school with GIAS URN: 999999")
  end

  context "when the CSV file does not exist" do
    subject(:run_invalid_task) { Rake::Task["eyl_fundng_eligible_schools:update"].invoke("nonexistent_file.csv") }

    it "raises an error" do
      expect { run_invalid_task }.to raise_error("File not found: nonexistent_file.csv")
    end
  end

  context "when the file is not a valid CSV file" do
    let(:invalid_csv_file) do
      tempfile <<~CSV
        gias_urn
        "123456
      CSV
    end

    subject(:run_invalid_csv_task) { Rake::Task["eyl_fundng_eligible_schools:update"].invoke(invalid_csv_file.path) }

    it "raises a CSV parsing error" do
      expect { run_invalid_csv_task }.to raise_error(CSV::MalformedCSVError)
    end
  end
end
