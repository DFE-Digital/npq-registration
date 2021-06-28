require "rails_helper"

RSpec.describe Services::ImportGiasSchools do
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
    end

    it "creates not existent schools" do
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

        expect(school.close_date ? school.close_date.strftime("%d-%m-%Y") : nil).to eql(row["CloseDate"])
        expect(school.ukprn).to eql(row["UKPRN"])
        expect(school.last_changed_date ? school.last_changed_date.strftime("%d-%m-%Y") : "").to eql(row["LastChangedDate"])

        expect(school.address_1).to eql(row["Street"])
        expect(school.address_2).to eql(row["Locality"])
        expect(school.address_3).to eql(row["Address3"])
        expect(school.town).to eql(row["Town"])
        expect(school.county).to eql(row["County (name)"])
        expect(school.postcode).to eql(row["Postcode"])
        expect(school.easting.to_s).to eql(row["Easting"].to_s)
        expect(school.northing.to_s).to eql(row["Northing"].to_s)
        expect(school.region).to eql(row["RSCRegion (name)"])
        expect(school.country).to eql(row["Country (name)"])
      end
    end

    it "applies updates correctly" do
      described_class.new.call

      expect {
        described_class.new.call
      }.not_to change(School, :count)

      expect(School.first.name).to eql("The Aldgate School 2")
    end
  end
end
