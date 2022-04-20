require "rails_helper"

RSpec.describe Services::ChildcareProviders::Importer do
  subject { described_class.new(file_name: file_name) }

  let(:run_import) { subject.call }

  describe "#call" do
    def find_and_slice_childcare_provider(urn)
      childcare_provider = ChildcareProvider.find_by(urn: urn)

      childcare_provider.as_json(except: %i[id created_at updated_at])
    end

    context "with all rows valid" do
      # File contains sample of real data
      let(:file_name) { "spec/fixtures/files/childcare_providers_sample.csv" }

      it "returns no errors" do
        run_import
        expect(subject.import_errors).to eq({})
      end

      it "imports rows as ChildcareProvider records" do
        expect { run_import }.to change { ChildcareProvider.count }.from(0).to(4)

        expect(find_and_slice_childcare_provider("520917")).to eq({
          "address_1" => "21 Roseville Road",
          "address_2" => "Harehills",
          "address_3" => nil,
          "close_date" => nil,
          "country" => nil,
          "county" => nil,
          "easting" => nil,
          "establishment_number" => nil,
          "establishment_status_code" => "1",
          "establishment_status_name" => "Open",
          "establishment_type_code" => nil,
          "establishment_type_name" => nil,
          "high_pupil_premium" => false,
          "la_code" => nil,
          "la_name" => nil,
          "last_changed_date" => nil,
          "name" => "Rosewood Nursery",
          "northing" => nil,
          "postcode" => "LS8 5DT",
          "postcode_without_spaces" => "LS85DT",
          "region" => "Yorkshire and The Humber",
          "town" => "Leeds",
          "ukprn" => nil,
          "urn" => "520917",
        })

        expect(find_and_slice_childcare_provider("EY790942")).to eq({
          "address_1" => "High Ridge Park",
          "address_2" => "Rothwell",
          "address_3" => nil,
          "close_date" => nil,
          "country" => nil,
          "county" => nil,
          "easting" => nil,
          "establishment_number" => nil,
          "establishment_status_code" => "1",
          "establishment_status_name" => "Open",
          "establishment_type_code" => nil,
          "establishment_type_name" => nil,
          "high_pupil_premium" => false,
          "la_code" => nil,
          "la_name" => nil,
          "last_changed_date" => nil,
          "name" => "Daisy Chain Childcare",
          "northing" => nil,
          "postcode" => "LS26 0NL",
          "postcode_without_spaces" => "LS260NL",
          "region" => "Yorkshire and The Humber",
          "town" => "Leeds",
          "ukprn" => nil,
          "urn" => "EY790942",
        })

        expect(find_and_slice_childcare_provider("EY565343")).to eq({
          "address_1" => "34 Church Street",
          "address_2" => "Stapleford",
          "address_3" => nil,
          "close_date" => nil,
          "country" => nil,
          "county" => nil,
          "easting" => nil,
          "establishment_number" => nil,
          "establishment_status_code" => "1",
          "establishment_status_name" => "Open",
          "establishment_type_code" => nil,
          "establishment_type_name" => nil,
          "high_pupil_premium" => false,
          "la_code" => nil,
          "la_name" => nil,
          "last_changed_date" => nil,
          "name" => "Sparkle Daycare",
          "northing" => nil,
          "postcode" => "NG9 8DJ",
          "postcode_without_spaces" => "NG98DJ",
          "region" => "East Midlands",
          "town" => "NOTTINGHAM",
          "ukprn" => nil,
          "urn" => "EY565343",
        })

        expect(find_and_slice_childcare_provider("EY426355")).to eq({
          "address_1" => "The Old Library",
          "address_2" => "Bath Road",
          "address_3" => nil,
          "close_date" => nil,
          "country" => nil,
          "county" => nil,
          "easting" => nil,
          "establishment_number" => nil,
          "establishment_status_code" => "1",
          "establishment_status_name" => "Open",
          "establishment_type_code" => nil,
          "establishment_type_name" => nil,
          "high_pupil_premium" => false,
          "la_code" => nil,
          "la_name" => nil,
          "last_changed_date" => nil,
          "name" => "Cricklade Preschool Playgroup",
          "northing" => nil,
          "postcode" => "SN6 6AT",
          "postcode_without_spaces" => "SN66AT",
          "region" => "South West",
          "town" => "Cricklade",
          "ukprn" => nil,
          "urn" => "EY426355",
        })
      end

      it "returns the correct number of imported records" do
        run_import
        expect(subject.imported_records).to eq(4)
      end
    end

    context "with invalid rows" do
      # File contains sample of real data
      let(:file_name) { "spec/fixtures/files/childcare_providers_sample_with_errors.csv" }

      it "returns errors for invalid rows" do
        run_import
        expect(subject.import_errors).to eq({
          3 => ["Validation failed: Urn can't be blank"],
        })
      end

      it "imports valid rows" do
        expect { run_import }.to change { ChildcareProvider.count }.from(0).to(1)

        expect(find_and_slice_childcare_provider("520917")).to eq({
          "address_1" => "21 Roseville Road",
          "address_2" => "Harehills",
          "address_3" => nil,
          "close_date" => nil,
          "country" => nil,
          "county" => nil,
          "easting" => nil,
          "establishment_number" => nil,
          "establishment_status_code" => "1",
          "establishment_status_name" => "Open",
          "establishment_type_code" => nil,
          "establishment_type_name" => nil,
          "high_pupil_premium" => false,
          "la_code" => nil,
          "la_name" => nil,
          "last_changed_date" => nil,
          "name" => "Rosewood Nursery",
          "northing" => nil,
          "postcode" => "LS8 5DT",
          "postcode_without_spaces" => "LS85DT",
          "region" => "Yorkshire and The Humber",
          "town" => "Leeds",
          "ukprn" => nil,
          "urn" => "520917",
        })
      end

      it "returns the correct number of imported records" do
        run_import
        expect(subject.imported_records).to eq(1)
      end
    end

    context "with file that doesn't exist" do
      # File contains sample of real data
      let(:file_name) { "spec/fixtures/files/fake_file.csv" }

      it "returns an error and creates no records" do
        expect {
          expect { run_import }.to(raise_error(RuntimeError, "File not found: #{file_name}"))
        }.to_not(change { ChildcareProvider.count })

        expect(subject.imported_records).to eq(0)
      end
    end
  end
end
