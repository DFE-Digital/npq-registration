require "rails_helper"

RSpec.describe Guidance::IndexPage do
  subject(:guidance_index_page) { described_class.new }

  describe "#sections" do
    it "returns an empty array" do
      expect(guidance_index_page.sections).to eq({})
    end
  end

  describe "#index_page?" do
    it "returns true" do
      expect(guidance_index_page.index_page?).to be true
    end
  end
end
