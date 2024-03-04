CSV.read(Rails.root.join("db/data/schools/schools.csv"), headers: true).tap do |data|
  if Rails.env.in?(%w[review development])
    Rails.logger.info("Importing 1000 schools")

    School.insert_all(data.first(1000).map(&:to_h))
  else
    Rails.logger.info("Importing #{data.length} schools")

    School.insert_all(data.map(&:to_h))
  end
end
