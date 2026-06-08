# frozen_string_literal: true

RSpec.shared_context "with default nursery", shared_context: :metadata do
  let(:default_nursery) do
    create(:private_childcare_provider,
           provider_urn: "EY487263",
           provider_name: "searchable childcare provider",
           address_1: "street 1",
           town: "manchester",
           early_years_individual_registers: %w[CCR VCR EYR])
  end

  before { default_nursery }
end

RSpec.configure do |config|
  config.include_context "with default nursery", :with_default_nursery
end
