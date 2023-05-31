require "rails_helper"

RSpec.describe GeoLocalAuthority, type: :model do
  before do
    geojson_path = "lib/local_authority_geojsons/Local_Authority_Districts_December_2022_Boundaries_UK_BUC_143497700576642915.geojson"

    Services::GeojsonLoader.reload_geojsons(geojson_path)

    Geocoder.configure(lookup: :test)
    Geocoder::Lookup::Test.add_stub(
      "Department for Education, Westminster", [{
        "latitude" => 51.4979314,
        "longitude" => -0.13016544222858017,
        "address" => "Department for Education, 20, Great Smith Street, Westminster, Millbank, London, Greater London, England, SW1P 3BT, United Kingdom",
        "state" => "England",
        "country" => "United Kingdom",
        "country_code" => "gb",
      }]
    )
    Geocoder::Lookup::Test.add_stub(
      "Manchester Airport", [{
        "latitude" => 53.350342049999995,
        "longitude" => -2.280369252664295,
        "address" => "Manchester Airport, Castle Mill Lane, Ashley, Manchester, Cheshire East, England, M90 1QX, United Kingdom",
        "state" => "England",
        "country" => "United Kingdom",
        "country_code" => "gb",
      }]
    )
    Geocoder::Lookup::Test.add_stub(
      "Belfast City Airport", [{
        "latitude" => 54.614828,
        "longitude" => -5.8703437,
        "address" => "Bushmills Bar, Sydenham Bypass, Sydenham, Belfast, County Down, Ulster, Northern Ireland, BT3 9JH, United Kingdom",
        "state" => "Northern Ireland",
        "country" => "United Kingdom",
        "country_code" => "gb",
      }]
    )
    Geocoder::Lookup::Test.add_stub(
      "Edinburgh Airport", [{
        "latitude" => 55.950128899999996,
        "longitude" => -3.3595079855289756,
        "address" => "Edinburgh Airport, Meadowfield Road, Gogar, City of Edinburgh, Scotland, EH12 0AU, United Kingdom",
        "state" => "Scotland",
        "country" => "United Kingdom",
        "country_code" => "gb",
      }]
    )
    Geocoder::Lookup::Test.add_stub(
      "Cardiff Airport", [{
        "latitude" => 51.397871550000005,
        "longitude" => -3.3445890119919994,
        "address" => "Cardiff Airport, B4265, Fonmon, Rhoose, Penmark, Vale of Glamorgan, Wales, CF62 3BL, United Kingdom",
        "state" => "Wales",
        "country" => "United Kingdom",
        "country_code" => "gb",
      }]
    )

    Geocoder::Lookup::Test.add_stub(
      "Sydney Opera House", [{
        "latitude" => -33.85719805,
        "longitude" => 151.21512338473752,
        "address" => "Sydney Opera House, 2, Macquarie Street, Quay Quarter, Sydney, Council of the City of Sydney, New South Wales, 2000, Australia",
        "state" => "New South Wales",
        "country" => "Australia",
        "country_code" => "au",
      }]
    )
  end

  describe "#nearest_three_to" do
    def check_nearest_three_to(location)
      described_class.nearest_three_to(location).pluck(:name)
    end

    it "returns the three nearest local authorities" do
      # Do some quick checks around the UK to check it works in various areas
      expect(check_nearest_three_to("Department for Education, Westminster")).to eq(%w[Westminster Lambeth Wandsworth])
      expect(check_nearest_three_to("Manchester Airport")).to eq(["Manchester", "Cheshire East", "Trafford"])
      expect(check_nearest_three_to("Belfast City Airport")).to eq(["Belfast", "Ards and North Down", "Lisburn and Castlereagh"])
      expect(check_nearest_three_to("Edinburgh Airport")).to eq(["City of Edinburgh", "West Lothian", "Fife"])
      expect(check_nearest_three_to("Cardiff Airport")).to eq(["Vale of Glamorgan", "Cardiff", "Rhondda Cynon Taf"])

      # And one across the world to check it doesn't break
      expect(check_nearest_three_to("Sydney Opera House")).to eq(["Cornwall", "Isles of Scilly", "South Hams"])
    end
  end
end
