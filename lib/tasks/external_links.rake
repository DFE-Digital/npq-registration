namespace :external_links do
  desc "Verify all external links"
  task verify: :environment do
    ExternalLink.verify_all
  end
end
