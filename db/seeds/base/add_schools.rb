CSV.read(Rails.root.join("db/seeds/schools.csv"), headers: true).tap do |data|
  Rails.logger.info("Importing all schools")

  data.each_slice(1000) do |schools|
    School.insert_all(schools.map(&:to_h))
  end
end
