# frozen_string_literal: true

require "rails_helper"

class TestQuery
  include API::Concerns::Orderable
end

class Test < ApplicationRecord
  include ActiveModel::Attributes

  attribute :foo
  attribute :bar
end

RSpec.describe API::Concerns::Orderable do
  let(:query) { TestQuery.new }

  describe "#sort_order" do
    it "returns a formatted sort order relative to the model" do
      sort_order = query.sort_order(sort: "-foo,bar,invalid", model: Test, default: { id: :asc })
      expect(sort_order).to eq("tests.foo DESC, tests.bar ASC")
    end

    it "returns nil when there is no sort" do
      expect(query.sort_order(sort: " ", model: Test)).to be_nil
    end

    it "returns the default sort order when there is no sort" do
      default = { created_at: :asc }
      sort_order = query.sort_order(sort: nil, default:, model: Test)
      expect(sort_order).to eq(default)
    end
  end
end
