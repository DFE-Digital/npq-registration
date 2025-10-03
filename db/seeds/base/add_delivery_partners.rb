first_lead_provider = LeadProvider.first
raise "No lead providers found!" unless first_lead_provider

EDU_NAMES = [
  "Bright Futures Academy",
  "The Learning Hub",
  "NextGen Education",
  "Aspire Teaching Institute",
  "Pathway Scholars",
  "The Knowledge Centre",
  "Elevate Academy",
  "Inspire Teaching Hub",
  "Pioneer Learning",
  "The Growth Academy"
].freeze

100.times do
  FactoryBot.create(
    :delivery_partner,
    name: EDU_NAMES.sample + " #{Faker::Number.unique.number(digits: 3)}",
    lead_providers: [first_lead_provider]
  )
end

LeadProvider.where.not(id: first_lead_provider.id).find_each do |lead_provider|
  10.times do
    delivery_partner = FactoryBot.create(
      :delivery_partner,
      name: EDU_NAMES.sample + " #{Faker::Number.unique.number(digits: 3)}",
      lead_providers: [lead_provider]
    )

    Cohort.all.sample(3).each do |cohort|
      FactoryBot.create(
        :delivery_partnership,
        delivery_partner: delivery_partner,
        lead_provider: lead_provider,
        cohort: cohort
      )
    end
  end
end
