CSV.read(Rails.root.join("db/data/private_childcare_providers/private_childcare_providers.csv"), headers: true).tap do |data|
  if Rails.env.in?(%w[review development])
    Rails.logger.info("Importing 1000 private childcare providers")

    PrivateChildcareProvider.insert_all(data.first(1000).map(&:to_h))
  else
    Rails.logger.info("Importing #{data.length} private childcare providers")

    PrivateChildcareProvider.insert_all(data.map(&:to_h))
  end
end
