module Services
  class GeojsonLoader
    def self.reload_geojsons(geojson_path)
      empty_database
      load_geojsons(geojson_path)
    end

    def self.empty_database
      GeoLocalAuthority.delete_all
    end

    def self.read_file(geojson_path)
      file = File.read(geojson_path)
      features = RGeo::GeoJSON.decode(file, json_parser: :json)
    end

    def self.load_geojsons(geojson_path)
      Rails.logger.debug("Loading #{geojson_path}")

      features = read_file(geojson_path)

      features.each do |feature|
        geo_local_authority = GeoLocalAuthority.new
        geo_local_authority.name = feature.properties["LAD22NM"]
        geo_local_authority.geometry = feature.geometry
        geo_local_authority.save!
      end
    end

    class Shape
      attr_reader :geojson_record

      def initialize(geojson_record)
        @geojson_record = geojson_record
      end

      delegate :geometry,
               to: :geojson_record

      def name
        geojson_record.attributes["LAD22NM"]
      end
    end
  end
end
