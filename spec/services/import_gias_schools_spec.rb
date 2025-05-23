require "rails_helper"

RSpec.describe ImportGiasSchools do
  let(:date_string) { Time.zone.today.strftime("%Y%m%d") }

  describe "#call" do
    before do
      stub_request(:get, "https://ea-edubase-api-prod.azurewebsites.net/edubase/downloads/public/edubasealldata#{date_string}.csv")
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host" => "ea-edubase-api-prod.azurewebsites.net",
          "User-Agent" => "Ruby",
        },
      )
      .to_return(status: 200, body: File.open(file_fixture("gias_sample.csv"), "r:iso-8859-1:UTF-8").read, headers: {})
      .to_return(status: 200, body: File.open(file_fixture("gias_update.csv"), "r:iso-8859-1:UTF-8").read, headers: {})
      .to_return(status: 200, body: File.open(file_fixture("gias_sample.csv"), "r:iso-8859-1:UTF-8").read, headers: {})
    end

    it "creates schools that don't exist" do
      expect { subject.call }.to change(School, :count).by(99)
    end

    it "does not create duplicates" do
      expect {
        described_class.new.call
        described_class.new.call
      }.to change(School, :count).by(99)
    end

    it "imports schools correctly" do
      subject.call

      rows = CSV.parse(File.open(file_fixture("gias_sample.csv"), "r:iso-8859-1:UTF-8").read, headers: true)

      school = School.find_by(urn: rows[0]["URN"])

      expect(school.establishment_type_code).to eql("2")

      rows.each do |row|
        school = School.find_by(urn: row["URN"])

        expect(school.la_code).to eql(row["LA (code)"])
        expect(school.la_name).to eql(row["LA (name)"])

        expect(school.establishment_number).to eql(row["EstablishmentNumber"])
        expect(school.name).to eql(row["EstablishmentName"])

        expect(school.establishment_status_code).to eql(row["EstablishmentStatus (code)"])
        expect(school.establishment_status_name).to eql(row["EstablishmentStatus (name)"])

        expect(school.establishment_type_code).to eql(row["TypeOfEstablishment (code)"])
        expect(school.establishment_type_name).to eql(row["TypeOfEstablishment (name)"])

        expect(school.phase_type).to eql(row["PhaseOfEducation (code)"].to_i)
        expect(school.phase_name).to eql(row["PhaseOfEducation (name)"])

        expect(school.close_date ? school.close_date.strftime("%d-%m-%Y") : nil).to eql(row["CloseDate"])
        expect(school.ukprn).to eql(row["UKPRN"])
        expect(school.last_changed_date ? school.last_changed_date.strftime("%d-%m-%Y") : "").to eql(row["LastChangedDate"])

        expect(school.address_1).to eql(row["Street"])
        expect(school.address_2).to eql(row["Locality"])
        expect(school.address_3).to eql(row["Address3"])
        expect(school.town).to eql(row["Town"])
        expect(school.county).to eql(row["County (name)"])
        expect(school.postcode).to eql(row["Postcode"])
        expect(school.postcode_without_spaces).to eql(row["Postcode"]&.gsub(" ", ""))
        expect(school.easting.to_s).to eql(row["Easting"].to_s)
        expect(school.northing.to_s).to eql(row["Northing"].to_s)
        expect(school.region).to eql(row["RSCRegion (name)"])
        expect(school.country).to eql(row["Country (name)"])

        expect(school.number_of_pupils).to eql(row["NumberOfPupils"].nil? ? nil : row["NumberOfPupils"].to_i)
      end
    end

    it "applies updates correctly" do
      described_class.new.call

      expect { described_class.new.call }.not_to change(School, :count)
      expect(School.first.name).to eql("The Aldgate School 2")
    end

    context "when there is a school with nil last_changed_date" do
      before do
        described_class.new.call
        School.first.update!(last_changed_date: nil)
      end

      it "applies updates correctly" do
        expect { described_class.new.call }.not_to change(School, :count)
        expect(School.first.name).to eql("The Aldgate School 2")
      end
    end

    context "with refresh_all flag" do
      before do
        described_class.new.call
        described_class.new.call
        School.update_all(name: "foo")
      end

      it "updates everything" do
        described_class.new(refresh_all: true).call

        expect(School.where(name: "foo").count).to be_zero
      end
    end

    context "when the file has an invalid header" do
      before do
        stub_request(:get, "https://ea-edubase-api-prod.azurewebsites.net/edubase/downloads/public/edubasealldata#{date_string}.csv")
          .with(
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Host" => "ea-edubase-api-prod.azurewebsites.net",
              "User-Agent" => "Ruby",
            },
          ).to_return(status: 200, body: File.open(file_fixture("invalid_csv_header.csv"), "r:iso-8859-1:UTF-8").read, headers: {})
      end

      it "raises a CSV::MalformedCSVError with the header line in the message" do
        expect { subject.call }.to raise_error(CSV::MalformedCSVError).with_message(/line: "header one", "/)
      end
    end

    context "when the get request is not successful" do
      before do
        stub_request(:get, "https://ea-edubase-api-prod.azurewebsites.net/edubase/downloads/public/edubasealldata#{date_string}.csv")
          .with(
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Host" => "ea-edubase-api-prod.azurewebsites.net",
              "User-Agent" => "Ruby",
            },
          ).to_return(status: 404, body: "Error from GIAS", headers: {})
      end

      it "raises a custom error" do
        expect { subject.call }.to raise_error(ImportGiasSchools::FileNotAvailableError).with_message(/Error from GIAS/)
      end
    end
  end
end
