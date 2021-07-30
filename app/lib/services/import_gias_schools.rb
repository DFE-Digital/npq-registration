require "csv"

module Services
  class ImportGiasSchools
    def call
      CSV.foreach(csv_file, headers: true, converters: [gias_converter]) do |row|
        school = School.find_or_create_by!(urn: row["URN"]) do |s|
          s.assign_attributes(attributes_from_row(row))
        end

        if row["LastChangedDate"].present? && (school.last_changed_date < row["LastChangedDate"])
          school.update!(attributes_from_row(row))
        end
      end
    ensure
      csv_file.close
      csv_file.unlink
    end

  private

    def gias_converter
      lambda do |value, field_info|
        case field_info.header
        when "TypeOfEstablishment (code)"
          value.to_i
        when "CloseDate", "LastChangedDate"
          Date.parse(value) if value.present?
        else
          value.to_s if value.present?
        end
      end
    end

    def attributes_from_row(row)
      {
        la_code: row["LA (code)"],
        la_name: row["LA (name)"],

        establishment_number: row["EstablishmentNumber"],
        name: row["EstablishmentName"],

        establishment_status_code: row["EstablishmentStatus (code)"],
        establishment_status_name: row["EstablishmentStatus (name)"],

        establishment_type_code: row["TypeOfEstablishment (code)"],
        establishment_type_name: row["TypeOfEstablishment (name)"],

        close_date: row["CloseDate"],
        ukprn: row["UKPRN"],
        last_changed_date: row["LastChangedDate"],

        address_1: row["Street"],
        address_2: row["Locality"],
        address_3: row["Address3"],
        town: row["Town"],
        county: row["County (name)"],
        postcode: row["Postcode"],
        postcode_without_spaces: row["Postcode"]&.gsub(" ", ""),
        easting: row["Easting"],
        northing: row["Northing"],
        region: row["RSCRegion (name)"],
        country: row["Country (name)"],
      }
    end

    def url_for_schools
      date_string = Time.zone.today.strftime("%Y%m%d")
      "https://ea-edubase-api-prod.azurewebsites.net/edubase/downloads/public/edubasealldata#{date_string}.csv"
    end

    def csv_file
      return @csv_file if @csv_file

      uri = URI(url_for_schools)
      tempfile = Tempfile.new

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Get.new uri

        http.request request do |response|
          File.open tempfile.path, "w" do |io|
            response.read_body do |chunk|
              converted_chunk = Iconv.conv("utf-8", "ISO8859-1", chunk)
              io.write converted_chunk
            end
          end
        end
      end

      @csv_file = tempfile
    end
  end
end
