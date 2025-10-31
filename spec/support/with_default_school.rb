# frozen_string_literal: true

RSpec.shared_context "with default school", shared_context: :metadata do
  before do
    return if School.where(urn: 100_000).exists?

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")
  end
end

RSpec.configure do |config|
  config.include_context "with default school", :with_default_school
end
