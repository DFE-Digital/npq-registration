require "rails_helper"

RSpec.describe "update_eyl_funding_eligible_schools_list:update" do
  let(:previous_file_path) { "lib/eyl_funding_eligible_schools/2022-11-30/eligible-schools.csv" }
  let(:previous_csv_content) do
    <<~CSV
      gias_urn
      123456
      789012
      111111
    CSV
  end

  let(:new_csv_file) do
    tempfile <<~CSV
      URN,EstablishmentName,EstablishmentPostcode
      123456,School One,AB1 2CD
      789012,School Two,EF3 4GH
      999999,New School,IJ5 6KL
    CSV
  end

  before do
    create(:school, urn: "123456", eyl_funding_eligible: false, establishment_status_code: 0, establishment_status_name: "Unknown")
    create(:school, urn: "789012", eyl_funding_eligible: false, establishment_status_code: 0, establishment_status_name: "Unknown")
    create(:school, urn: "111111", eyl_funding_eligible: true, establishment_status_code: 1, establishment_status_name: "Open")
    # Create school with postcode matching the new school but different URN for testing duplication
    create(:school, urn: "888888", postcode: "IJ5 6KL", name: "Old School Name")

    # Stub the previous file's existence and content
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(previous_file_path).and_return(true)
    allow(CSV).to receive(:read).and_call_original
    allow(CSV).to receive(:read).with(previous_file_path, headers: true).and_return(CSV.parse(previous_csv_content, headers: true))

    allow(Rails.logger).to receive(:info)
  end

  after { Rake::Task["update_eyl_funding_eligible_schools_list:update"].reenable }

  subject(:run_task) { Rake::Task["update_eyl_funding_eligible_schools_list:update"].invoke(new_csv_file.path) }

  it "updates existing schools to be EYL funding eligible and marks them as open" do
    run_task

    school1 = School.find_by(urn: "123456")
    school2 = School.find_by(urn: "789012")

    expect(school1.eyl_funding_eligible).to be true
    expect(school1.establishment_status_code).to eq("1")
    expect(school1.establishment_status_name).to eq("Open")

    expect(school2.eyl_funding_eligible).to be true
    expect(school2.establishment_status_code).to eq("1")
    expect(school2.establishment_status_name).to eq("Open")
  end

  it "marks schools not in the new list as closed" do
    run_task

    school = School.find_by(urn: "111111")
    expect(school.establishment_status_code).to eq("2")
    expect(school.establishment_status_name).to eq("Closed")
  end

  it "handles new schools by duplicating existing schools with matching postcodes" do
    run_task

    new_school = School.find_by(urn: "999999")
    expect(new_school).to be_present
    expect(new_school.name).to eq("New School")
    expect(new_school.postcode).to eq("IJ5 6KL")
    expect(new_school.eyl_funding_eligible).to be true
    expect(new_school.establishment_status_code).to eq("1")
    expect(new_school.establishment_status_name).to eq("Open")
  end

  it "logs information about the update process" do
    run_task

    expect(Rails.logger).to have_received(:info).with("Fetching previous schools from CSV file: #{previous_file_path}")
    expect(Rails.logger).to have_received(:info).with("Fetched Records: 3")
    expect(Rails.logger).to have_received(:info).with("Updating schools from CSV file: #{new_csv_file.path}")
    expect(Rails.logger).to have_received(:info).with("Update finished")
    expect(Rails.logger).to have_received(:info).with("Updated Records: 2")
  end

  context "when the new CSV file does not exist" do
    subject(:run_invalid_task) { Rake::Task["update_eyl_funding_eligible_schools_list:update"].invoke("nonexistent_file.csv") }

    it "raises an error" do
      expect { run_invalid_task }.to raise_error("File not found: nonexistent_file.csv")
    end
  end

  context "when the previous CSV file does not exist" do
    before do
      allow(File).to receive(:exist?).with(previous_file_path).and_return(false)
    end

    it "raises an error" do
      expect { run_task }.to raise_error("File not found: #{previous_file_path}")
    end
  end

  context "when the new CSV file is malformed" do
    let(:invalid_csv_file) do
      tempfile <<~CSV
        URN,EstablishmentName,EstablishmentPostcode
        123456,School One,AB1 2CD
        "789012,School Two,EF3 4GH
        999999,New School,IJ5 6KL
      CSV
    end

    subject(:run_with_invalid_csv) { Rake::Task["update_eyl_funding_eligible_schools_list:update"].invoke(invalid_csv_file.path) }

    it "raises a CSV parsing error" do
      expect { run_with_invalid_csv }.to raise_error(CSV::MalformedCSVError)
    end
  end

  context "when the previous CSV file is malformed" do
    before do
      allow(CSV).to receive(:read).with(previous_file_path, headers: true).and_raise(CSV::MalformedCSVError.new("Invalid CSV format", 1))
    end

    it "raises a CSV parsing error" do
      expect { run_task }.to raise_error(CSV::MalformedCSVError)
    end
  end

  context "when the new CSV file has missing required columns" do
    let(:missing_columns_csv_file) do
      tempfile <<~CSV
        IncorrectColumn,EstablishmentName,EstablishmentPostcode
        123456,School One,AB1 2CD
        789012,School Two,EF3 4GH
      CSV
    end

    subject(:run_with_missing_columns) { Rake::Task["update_eyl_funding_eligible_schools_list:update"].invoke(missing_columns_csv_file.path) }

    it "fails when the URN column is missing" do
      expect { run_with_missing_columns }.to raise_error(KeyError, "key not found: URN")
    end
  end

  context "when the previous CSV file has missing required columns" do
    before do
      allow(CSV).to receive(:read).with(previous_file_path, headers: true).and_return(
        CSV.parse("wrong_column\n123456\n789012\n111111", headers: true),
      )
    end

    it "fails when the gias_urn column is missing" do
      expect { run_task }.to raise_error(KeyError, "key not found: gias_urn")
    end
  end
end
