class GeoLocalAuthority < ApplicationRecord
  include RGeo::ActiveRecord::GeometryMixin

  SRID = 27_700

  def self.nearest_three_to(string)
    location = Geocoder.search(string).first
    by_distance(location.longitude.to_f, location.latitude.to_f).limit(3)
  end

  def self.by_distance(longitude, latitude)
    # Transform the given lon/lat to have an SRID of 27700 (the SRID of the GeoLocalAuthority geometries)
    transformed_point = RGeo::CoordSys::Proj4.transform_coords(
      RGeo::CoordSys::Proj4.new("EPSG:4326"),
      RGeo::CoordSys::Proj4.new("EPSG:27700"),
      longitude,
      latitude,
    )

    target_latitude = transformed_point[1]
    target_longitude = transformed_point[0]

    # Create a point representing the target coordinates, with the SRID specified
    # If you don't specify the SRID it will default to 0, which will cause an error
    point_sql = "SRID=#{SRID};POINT(#{target_longitude} #{target_latitude})"

    arel = Arel.sql("geometry <-> '#{point_sql}'::geometry")

    order(arel)
  end
end
