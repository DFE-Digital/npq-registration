# frozen_string_literal: true

require "tempfile"
require "rails_helper"

RSpec.describe Importers::CreateCohort do
  subject(:importer) { described_class.new(path_to_csv:) }

  let(:csv) { Tempfile.new("data.csv") }
  let(:path_to_csv) { csv.path }

  describe "#call" do
    before do
      csv.write "start-year,registration-start-date"
      csv.write "\n"
      csv.write "2026,2026/05/10"
      csv.write "\n"
      csv.write "2027,2027/05/10"
      csv.write "\n"
      csv.write "2028,2028/05/10"
      csv.write "\n"
      csv.write "2029,2029/05/10"
      csv.write "\n"
      csv.close
    end

    it "creates cohort records" do
      expect { importer.call }.to change(Cohort, :count).by(4)
    end

    it "sets the correct start year on the record" do
      importer.call

      expect(Cohort.order(:start_year).last.start_year).to eq 2029
    end

    it "sets the correct registration start date on the record" do
      importer.call

      cohort_2029 = Cohort.find_by(start_year: 2029)
      expect(cohort_2029.registration_start_date).to eq Date.new(2029, 5, 10)
    end

    it "only creates one cohort record per year" do
      original_cohort_count = Cohort.count
      importer.call

      expect(Cohort.select("start_year").group("start_year").pluck(:start_year).size).to be original_cohort_count + 4
    end
  end
end
