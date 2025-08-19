CSV.read(Rails.root.join("db/seeds/data/schools.csv"), headers: true).tap do |data|
  import_count = 0
  batch = []

  data.each do |row|
    batch << row.to_h
    next unless batch.length >= 1000

    Rails.logger.info("Importing #{import_count += 1000} schools")

    School.insert_all(batch)
    batch = []
  end

  unless batch.empty?
    Rails.logger.info("Importing #{import_count + batch.length} schools")
    School.insert_all(batch)
  end
end
