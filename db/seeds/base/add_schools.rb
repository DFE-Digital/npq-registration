CSV.read(Rails.root.join("db/seeds/schools.csv"), headers: true).tap do |data|
  Rails.logger.info("Importing all schools")

  School.insert_all(data.map(&:to_h))
end
