CSV.read(Rails.root.join("db/seeds/private_childcare_providers.csv"), headers: true).tap do |data|
  Rails.logger.info("Importing 1000 private childcare providers")

  PrivateChildcareProvider.insert_all(data.first(1000).map(&:to_h))
end
