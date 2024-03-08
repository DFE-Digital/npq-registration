CSV.read(Rails.root.join("db/seeds/schools.csv"), headers: true).tap do |data|
  Rails.logger.info("Importing 1000 schools")

  School.insert_all(data.first(1000).map(&:to_h))
end
