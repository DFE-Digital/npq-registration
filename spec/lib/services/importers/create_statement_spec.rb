# frozen_string_literal: true

require "tempfile"

RSpec.describe Importers::CreateStatement do
  subject(:importer) { described_class.new(path_to_csv:) }

  let(:csv) { Tempfile.new("data.csv") }
  let(:path_to_csv) { csv.path }
  let!(:cohort_2023) { create(:cohort, start_year: 2023) }

  describe "#call" do
    before do
      csv.write "month,year,deadline_date,payment_date,output_fee,cohort"
      csv.write "\n"
      csv.write "1,2024,2023-12-25,2024-1-25,false,2023"
      csv.write "\n"
      csv.write "2,2024,2024-1-25,2024-2-25,true,2023"
      csv.write "\n"
      csv.close
    end

    it "creates statements correctly" do
      expect {
        importer.call
        importer.call
      }.to change(Statement, :count).by(20)
    end

    it "populates statements correctly" do
      importer.call

      expect(
        Statement.find_by(
          month: 1,
          year: 2024,
          cohort: cohort_2023,
          deadline_date: Date.new(2023, 12, 25),
          payment_date: Date.new(2024, 1, 25),
          output_fee: false,
        ),
      ).to be_present

      expect(
        Statement.find_by(
          month: 2,
          year: 2024,
          cohort: cohort_2023,
          deadline_date: Date.new(2024, 1, 25),
          payment_date: Date.new(2024, 2, 25),
          output_fee: true,
        ),
      ).to be_present
    end
  end
end
