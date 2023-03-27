require "rails_helper"

RSpec.describe Services::PrivateChildcareProviders::Importer do
  subject do
    described_class.new(
      file_name:,
      csv_row_parser:,
    )
  end

  let(:run_import) { subject.call }

  describe "#call" do
    def find_and_slice_private_childcare_provider(urn)
      private_childcare_provider = PrivateChildcareProvider.find_by(provider_urn: urn)

      private_childcare_provider.as_json(except: %i[id created_at updated_at])
    end

    context "private childcare providers" do
      let(:csv_row_parser) { Services::PrivateChildcareProviders::Importer::ChildcareProviderWrappedCSVRow }

      context "with all rows valid" do
        # File contains sample of real data
        let(:file_name) { "spec/fixtures/files/private_childcare_providers_sample.csv" }

        it "returns no errors" do
          run_import
          expect(subject.import_errors).to eq({})
        end

        it "imports rows as PrivateChildcareProvider records" do
          expect { run_import }.to change(PrivateChildcareProvider, :count).from(0).to(7)

          expect(find_and_slice_private_childcare_provider("520917")).to eq({
            "address_1" => "21 Roseville Road",
            "address_2" => "Harehills",
            "address_3" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Leeds",
            "ofsted_region" => "North East, Yorkshire and the Humber",
            "places" => 60,
            "postcode" => "LS8 5DT",
            "postcode_without_spaces" => "LS85DT",
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "provider_name" => "Rosewood Nursery",
            "provider_status" => "Active",
            "provider_urn" => "520917",
            "region" => "Yorkshire and The Humber",
            "registered_person_name" => "The Leeds Teaching Hospitals NHS Trust",
            "registered_person_urn" => "RP901956",
            "registration_date" => "24/10/1983",
            "town" => "Leeds",
          })

          expect(find_and_slice_private_childcare_provider("EY790942")).to eq({
            "address_1" => "High Ridge Park",
            "address_2" => "Rothwell",
            "address_3" => nil,
            "early_years_individual_registers" => %w[CCR],
            "local_authority" => "Leeds",
            "ofsted_region" => "North East, Yorkshire and the Humber",
            "provider_name" => "Daisy Chain Childcare",
            "provider_status" => "Active",
            "places" => 50,
            "postcode" => "LS26 0NL",
            "postcode_without_spaces" => "LS260NL",
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "region" => "Yorkshire and The Humber",
            "registered_person_name" => "Daisy Chain Childcare Limited",
            "registered_person_urn" => "RP910702",
            "registration_date" => "23/03/1996",
            "town" => "Leeds",
            "provider_urn" => "EY790942",
          })

          expect(find_and_slice_private_childcare_provider("EY565343")).to eq({
            "address_1" => "34 Church Street",
            "address_2" => "Stapleford",
            "address_3" => nil,
            "early_years_individual_registers" => %w[CCR VCR],
            "local_authority" => "Nottinghamshire",
            "ofsted_region" => "East Midlands",
            "provider_name" => "Sparkle Daycare",
            "provider_status" => "Active",
            "places" => 18,
            "postcode" => "NG9 8DJ",
            "postcode_without_spaces" => "NG98DJ",
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "region" => "East Midlands",
            "registered_person_name" => "Walker, Emma",
            "registered_person_urn" => "RP514806",
            "registration_date" => "20/05/2008",
            "town" => "NOTTINGHAM",
            "provider_urn" => "EY565343",
          })

          expect(find_and_slice_private_childcare_provider("EY426355")).to eq({
            "address_1" => "The Old Library",
            "address_2" => "Bath Road",
            "address_3" => nil,
            "early_years_individual_registers" => %w[EYR],
            "local_authority" => "Wiltshire",
            "ofsted_region" => "South West",
            "provider_name" => "Cricklade Preschool Playgroup",
            "provider_status" => "Active",
            "places" => 28,
            "postcode" => "SN6 6AT",
            "postcode_without_spaces" => "SN66AT",
            "provider_compulsory_childcare_register_flag" => false,
            "provider_early_years_register_flag" => true,
            "region" => "South West",
            "registered_person_name" => "Cricklade Preschool Playgroup",
            "registered_person_urn" => "RP901939",
            "registration_date" => "12/04/2011",
            "town" => "Cricklade",
            "provider_urn" => "EY426355",
          })

          expect(find_and_slice_private_childcare_provider("EY426356")).to eq({
            "address_1" => "The Old Library",
            "address_2" => "Bath Road",
            "address_3" => nil,
            "early_years_individual_registers" => %w[CCR EYR],
            "local_authority" => "Wiltshire",
            "ofsted_region" => "South West",
            "provider_name" => "Cricklade Preschool Playgroup",
            "provider_status" => "Active",
            "places" => 28,
            "postcode" => "SN6 6AT",
            "postcode_without_spaces" => "SN66AT",
            "provider_compulsory_childcare_register_flag" => false,
            "provider_early_years_register_flag" => true,
            "region" => "South West",
            "registered_person_name" => "Cricklade Preschool Playgroup",
            "registered_person_urn" => "RP901939",
            "registration_date" => "12/04/2011",
            "town" => "Cricklade",
            "provider_urn" => "EY426356",
          })

          expect(find_and_slice_private_childcare_provider("EY426357")).to eq({
            "address_1" => "The Old Library",
            "address_2" => "Bath Road",
            "address_3" => nil,
            "early_years_individual_registers" => %w[VCR EYR],
            "local_authority" => "Wiltshire",
            "ofsted_region" => "South West",
            "provider_name" => "Cricklade Preschool Playgroup",
            "provider_status" => "Active",
            "places" => 28,
            "postcode" => "SN6 6AT",
            "postcode_without_spaces" => "SN66AT",
            "provider_compulsory_childcare_register_flag" => false,
            "provider_early_years_register_flag" => false,
            "region" => "South West",
            "registered_person_name" => "Cricklade Preschool Playgroup",
            "registered_person_urn" => "RP901939",
            "registration_date" => "12/04/2011",
            "town" => "Cricklade",
            "provider_urn" => "EY426357",
          })

          expect(find_and_slice_private_childcare_provider("EY426358")).to eq({
            "address_1" => "The Old Library",
            "address_2" => "Bath Road",
            "address_3" => nil,
            "early_years_individual_registers" => %w[VCR],
            "local_authority" => "Wiltshire",
            "ofsted_region" => "South West",
            "provider_name" => "Cricklade Preschool Playgroup",
            "provider_status" => "Active",
            "places" => 28,
            "postcode" => "SN6 6AT",
            "postcode_without_spaces" => "SN66AT",
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => false,
            "region" => "South West",
            "registered_person_name" => "Cricklade Preschool Playgroup",
            "registered_person_urn" => "RP901939",
            "registration_date" => "12/04/2011",
            "town" => "Cricklade",
            "provider_urn" => "EY426358",
          })
        end

        it "returns the correct number of imported records" do
          run_import
          expect(subject.imported_records).to eq(7)
        end

        it "returns no errors for invalid rows" do
          run_import
          expect(subject.import_errors).to eq({})
        end

        context "with incorrect parser" do
          let(:csv_row_parser) { Services::PrivateChildcareProviders::Importer::ChildminderAgencyWrappedCSVRow }

          it "returns errors for invalid rows" do
            run_import
            expect(subject.import_errors.count).to eq(7)
          end

          it "imports no rows" do
            expect { run_import }.not_to(change(PrivateChildcareProvider, :count))
          end
        end
      end

      context "with invalid rows" do
        # File contains sample of real data
        let(:file_name) { "spec/fixtures/files/private_childcare_providers_sample_with_errors.csv" }

        it "returns errors for invalid rows" do
          run_import
          expect(subject.import_errors).to eq({
            3 => ["Validation failed: Provider urn can't be blank"],
            4 => ["Unknown Individual Register combinations value: ABC only"],
          })
        end

        it "imports valid rows" do
          expect { run_import }.to change(PrivateChildcareProvider, :count).from(0).to(1)

          expect(find_and_slice_private_childcare_provider("520917")).to eq({
            "address_1" => "21 Roseville Road",
            "address_2" => "Harehills",
            "address_3" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Leeds",
            "ofsted_region" => "North East, Yorkshire and the Humber",
            "places" => 60,
            "postcode" => "LS8 5DT",
            "postcode_without_spaces" => "LS85DT",
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "provider_name" => "Rosewood Nursery",
            "provider_status" => "Active",
            "provider_urn" => "520917",
            "region" => "Yorkshire and The Humber",
            "registered_person_name" => "The Leeds Teaching Hospitals NHS Trust",
            "registered_person_urn" => "RP901956",
            "registration_date" => "24/10/1983",
            "town" => "Leeds",
          })
        end

        it "returns the correct number of imported records" do
          run_import
          expect(subject.imported_records).to eq(1)
        end
      end

      context "with records that already exist" do
        let(:file_name) { "spec/fixtures/files/private_childcare_providers_sample.csv" }

        # the update file is the same as the import but the first two records have been changed
        let(:updates) do
          described_class.new(
            file_name: "spec/fixtures/files/private_childcare_providers_sample_with_updates.csv",
            csv_row_parser:,
          )
        end

        let(:run_update) { updates.call }

        before { run_import }

        it "makes the correct number of updates" do
          run_update
          expect(updates.updated_records).to be(2)
        end

        it "doesn't reinsert existing records" do
          run_update
          expect(updates.imported_records).to be(0)
        end

        it "makes the updates correctly" do
          expect(find_and_slice_private_childcare_provider("520917")).to eq({
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "address_1" => "21 Roseville Road",
            "address_2" => "Harehills",
            "address_3" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Leeds",
            "ofsted_region" => "North East, Yorkshire and the Humber",
            "places" => 60,
            "postcode" => "LS8 5DT",
            "postcode_without_spaces" => "LS85DT",
            "provider_name" => "Rosewood Nursery",
            "provider_status" => "Active",
            "provider_urn" => "520917",
            "region" => "Yorkshire and The Humber",
            "registered_person_name" => "The Leeds Teaching Hospitals NHS Trust",
            "registered_person_urn" => "RP901956",
            "registration_date" => "24/10/1983",
            "town" => "Leeds",
          })

          expect(find_and_slice_private_childcare_provider("EY790942")).to eq({
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "address_1" => "High Ridge Park",
            "address_2" => "Rothwell",
            "address_3" => nil,
            "early_years_individual_registers" => %w[CCR],
            "local_authority" => "Leeds",
            "ofsted_region" => "North East, Yorkshire and the Humber",
            "provider_name" => "Daisy Chain Childcare",
            "provider_status" => "Active",
            "places" => 50,
            "postcode" => "LS26 0NL",
            "postcode_without_spaces" => "LS260NL",
            "region" => "Yorkshire and The Humber",
            "registered_person_name" => "Daisy Chain Childcare Limited",
            "registered_person_urn" => "RP910702",
            "registration_date" => "23/03/1996",
            "town" => "Leeds",
            "provider_urn" => "EY790942",
          })

          run_update

          expect(find_and_slice_private_childcare_provider("520917")).to eq({
            "provider_compulsory_childcare_register_flag" => false,
            "provider_early_years_register_flag" => false,
            "address_1" => "21 Roseville Road",
            "address_2" => "Harehills",
            "address_3" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Leeds",
            "ofsted_region" => "North East, Yorkshire and the Humber",
            "places" => 60,
            "postcode" => "LS8 5DT",
            "postcode_without_spaces" => "LS85DT",
            "provider_name" => "Rosewood Nursery",
            "provider_status" => "Active",
            "provider_urn" => "520917",
            "region" => "Yorkshire and The Humber",
            "registered_person_name" => "The Leeds Teaching Hospitals NHS Trust",
            "registered_person_urn" => "RP901956",
            "registration_date" => "24/10/1983",
            "town" => "Leeds",
          })

          expect(find_and_slice_private_childcare_provider("EY790942")).to eq({
            "provider_compulsory_childcare_register_flag" => false,
            "provider_early_years_register_flag" => false,
            "address_1" => "High Ridge Park",
            "address_2" => "Rothwell",
            "address_3" => nil,
            "early_years_individual_registers" => %w[CCR],
            "local_authority" => "Leeds",
            "ofsted_region" => "North East, Yorkshire and the Humber",
            "provider_name" => "Daisy Chain Childcare",
            "provider_status" => "Active",
            "places" => 50,
            "postcode" => "LS26 0NL",
            "postcode_without_spaces" => "LS260NL",
            "region" => "Yorkshire and The Humber",
            "registered_person_name" => "Daisy Chain Childcare Limited",
            "registered_person_urn" => "RP910702",
            "registration_date" => "23/03/1996",
            "town" => "Leeds",
            "provider_urn" => "EY790942",
          })
        end
      end
    end

    context "private childminder agencies" do
      let(:csv_row_parser) { Services::PrivateChildcareProviders::Importer::ChildminderAgencyWrappedCSVRow }

      context "with all rows valid" do
        # File contains sample of real data
        let(:file_name) { "spec/fixtures/files/private_childminder_agencies_sample.csv" }

        it "returns no errors" do
          run_import
          expect(subject.import_errors).to eq({})
        end

        it "imports rows as PrivateChildcareProvider records" do
          expect { run_import }.to change(PrivateChildcareProvider, :count).from(0).to(2)

          expect(find_and_slice_private_childcare_provider("CA000006")).to eq({
            "address_1" => "108 Regent Studios",
            "address_2" => "1 Thane Villas",
            "address_3" => "London",
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Islington",
            "ofsted_region" => nil,
            "places" => nil,
            "postcode" => "N7 7PH",
            "postcode_without_spaces" => "N77PH",
            "provider_compulsory_childcare_register_flag" => nil,
            "provider_early_years_register_flag" => nil,
            "provider_name" => "Daryel Care",
            "provider_status" => "Active",
            "provider_urn" => "CA000006",
            "region" => nil,
            "registered_person_name" => nil,
            "registered_person_urn" => nil,
            "registration_date" => nil,
            "town" => nil,
          })
          expect(find_and_slice_private_childcare_provider("CA000012")).to eq({
            "address_1" => "157 - 159 St. Barnabas Road",
            "address_2" => "Woodford Green",
            "address_3" => "Essex",
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Redbridge",
            "ofsted_region" => nil,
            "places" => nil,
            "postcode" => "IG8 7DG",
            "postcode_without_spaces" => "IG87DG",
            "provider_compulsory_childcare_register_flag" => nil,
            "provider_early_years_register_flag" => nil,
            "provider_name" => "City Childcare Childminding Agency",
            "provider_status" => "Active",
            "provider_urn" => "CA000012",
            "region" => nil,
            "registered_person_name" => nil,
            "registered_person_urn" => nil,
            "registration_date" => nil,
            "town" => nil,
          })
        end

        it "returns the correct number of imported records" do
          run_import
          expect(subject.imported_records).to eq(2)
        end

        context "with incorrect parser" do
          let(:csv_row_parser) { Services::PrivateChildcareProviders::Importer::ChildcareProviderWrappedCSVRow }

          it "returns errors for invalid rows" do
            run_import
            expect(subject.import_errors.count).to eq(2)
          end

          it "imports no rows" do
            expect { run_import }.not_to(change(PrivateChildcareProvider, :count))
          end
        end
      end

      context "with invalid rows" do
        # File contains sample of real data
        let(:file_name) { "spec/fixtures/files/private_childminder_agencies_sample_with_errors.csv" }

        it "returns errors for invalid rows" do
          run_import
          expect(subject.import_errors).to eq({
            3 => ["Validation failed: Provider urn can't be blank"],
            4 => ["Unknown Individual Register combinations value: EYR"],
          })
        end

        it "imports valid rows" do
          expect { run_import }.to change(PrivateChildcareProvider, :count).from(0).to(1)

          expect(find_and_slice_private_childcare_provider("CA000006")).to eq({
            "address_1" => "108 Regent Studios",
            "address_2" => "1 Thane Villas",
            "address_3" => "London",
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Islington",
            "ofsted_region" => nil,
            "places" => nil,
            "postcode" => "N7 7PH",
            "postcode_without_spaces" => "N77PH",
            "provider_compulsory_childcare_register_flag" => nil,
            "provider_early_years_register_flag" => nil,
            "provider_name" => "Daryel Care",
            "provider_status" => "Active",
            "provider_urn" => "CA000006",
            "region" => nil,
            "registered_person_name" => nil,
            "registered_person_urn" => nil,
            "registration_date" => nil,
            "town" => nil,
          })
        end

        it "returns the correct number of imported records" do
          run_import
          expect(subject.imported_records).to eq(1)
        end
      end

      context "with records that already exist" do
        let(:file_name) { "spec/fixtures/files/private_childminder_agencies_sample.csv" }

        # the update file is the same as the import but the first record has been changed
        let(:updates) do
          described_class.new(
            file_name: "spec/fixtures/files/private_childminder_agencies_sample_with_updates.csv",
            csv_row_parser:,
          )
        end

        let(:run_update) { updates.call }

        before { run_import }

        it "makes the correct number of updates" do
          run_update

          expect(updates.updated_records).to be(1)
        end

        it "doesn't reinsert existing records" do
          run_update

          expect(updates.imported_records).to be(0)
        end

        it "makes the updates correctly" do
          expect(find_and_slice_private_childcare_provider("CA000006")).to eq({
            "address_1" => "108 Regent Studios",
            "address_2" => "1 Thane Villas",
            "address_3" => "London",
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Islington",
            "ofsted_region" => nil,
            "places" => nil,
            "postcode" => "N7 7PH",
            "postcode_without_spaces" => "N77PH",
            "provider_compulsory_childcare_register_flag" => nil,
            "provider_early_years_register_flag" => nil,
            "provider_name" => "Daryel Care",
            "provider_status" => "Active",
            "provider_urn" => "CA000006",
            "region" => nil,
            "registered_person_name" => nil,
            "registered_person_urn" => nil,
            "registration_date" => nil,
            "town" => nil,
          })

          run_update

          expect(find_and_slice_private_childcare_provider("CA000006")).to eq({
            "address_1" => "109 Regent Studios", # changed in updates csv
            "address_2" => "1 Thane Villas",
            "address_3" => "London",
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Islington",
            "ofsted_region" => nil,
            "places" => nil,
            "postcode" => "N7 7PH",
            "postcode_without_spaces" => "N77PH",
            "provider_compulsory_childcare_register_flag" => nil,
            "provider_early_years_register_flag" => nil,
            "provider_name" => "Daryel Care",
            "provider_status" => "Active",
            "provider_urn" => "CA000006",
            "region" => nil,
            "registered_person_name" => nil,
            "registered_person_urn" => nil,
            "registration_date" => nil,
            "town" => nil,
          })
        end
      end
    end

    context "with file that doesn't exist" do
      # File contains sample of real data
      let(:file_name) { "spec/fixtures/files/fake_file.csv" }
      let(:csv_row_parser) { Services::PrivateChildcareProviders::Importer::ChildcareProviderWrappedCSVRow }

      it "returns an error and creates no records" do
        expect {
          expect { run_import }.to(raise_error(RuntimeError, "File not found: #{file_name}"))
        }.not_to(change(PrivateChildcareProvider, :count))

        expect(subject.imported_records).to eq(0)
      end
    end
  end
end
