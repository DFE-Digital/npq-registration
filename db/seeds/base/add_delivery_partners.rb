# first lead provider will have 100 delivery partners - useful for showing what production volume will get up to
100.times do
  FactoryBot.create(:delivery_partner, lead_providers: Cohort.all.index_with { LeadProvider.first })
end

# other lead providers will have 10 delivery partners, each with a random sample of 3 cohorts
LeadProvider.excluding(LeadProvider.first).find_each do |lead_provider|
  DeliveryPartner.limit(10).find_each do |delivery_partner|
    Cohort.all.sample(3).each do |cohort|
      FactoryBot.create(:delivery_partnership, delivery_partner: delivery_partner, lead_provider: lead_provider, cohort: cohort)
    end
  end
end
