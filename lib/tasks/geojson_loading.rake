namespace :geojson do
  desc "Load geojsons into the database, will empty local authorities table first"
  task load: :environment do |_t, _args|
    geojson_path = "lib/local_authority_geojson/Local_Authority_Districts_December_2022_Boundaries_UK_BUC_143497700576642915.geojson"

    puts("Loading geojsons from #{geojson_path}")

    Services::GeojsonLoader.reload_geojsons(geojson_path)
  end

  desc "Load geojson file and output local authorities found"
  task test: :environment do |_t, _args|
    geojson_path = "lib/local_authority_geojson/Local_Authority_Districts_December_2022_Boundaries_UK_BUC_143497700576642915.geojson"

    features = Services::GeojsonLoader.read_file(geojson_path)

    puts "File contains #{features.count} local authority geometries"

    local_authorities_found = features.map { |feature| feature.properties["LAD22NM"] }.sort.join(", ")

    puts "Local Authorities found: #{local_authorities_found}"
  end
end
