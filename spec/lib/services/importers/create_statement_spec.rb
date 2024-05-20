# frozen_string_literal: true

require "rails_helper"
require "tempfile"

RSpec.describe Importers::CreateStatement do
  let(:csv) { Tempfile.new("data.csv") }
  let(:path_to_csv) { csv.path }
  let!(:cohort) { create(:cohort, start_year: 2023) }

  subject(:importer) { described_class.new(path_to_csv:) }

  describe "#call" do
    before do
      csv.write "name,cohort,deadline_date,payment_date,output_fee"
      csv.write "\n"
      csv.write "January 2024,2023,2023-12-25,2024-1-25,false"
      csv.write "\n"
      csv.write "February 2024,2023,2024-1-25,2024-2-25,true"
      csv.write "\n"
      csv.close
    end

    it "creates statements idempotently" do
      expect {
        importer.call
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
          cohort:,
          deadline_date: Date.new(2023, 12, 25),
          payment_date: Date.new(2024, 1, 25),
          output_fee: false,
        ),
      ).to be_present

      expect(
        Statement.find_by(
          month: 2,
          year: 2024,
          cohort:,
          deadline_date: Date.new(2024, 1, 25),
          payment_date: Date.new(2024, 2, 25),
          output_fee: true,
        ),
      ).to be_present
    end
  end
end
