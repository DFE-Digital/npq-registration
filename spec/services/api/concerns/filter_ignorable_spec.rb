# frozen_string_literal: true

require "rails_helper"

class TestQuery
  include API::Concerns::FilterIgnorable
end

RSpec.describe API::Concerns::FilterIgnorable do
  let(:query) { TestQuery.new }

  describe "#ignore?" do
    it { expect(query).to be_ignore(filter: " ") }
    it { expect(query).to be_ignore(filter: "") }
    it { expect(query).to be_ignore(filter: :ignore) }
    it { expect(query).not_to be_ignore(filter: nil) }
    it { expect(query).not_to be_ignore(filter: "value") }
  end
end
