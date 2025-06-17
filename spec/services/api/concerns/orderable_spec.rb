# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::Concerns::Orderable do
  let :model do
    Class.new(ApplicationRecord) do
      include ActiveModel::Attributes

      # As of Rails 7.2 the table is queried so this needs backing by a real table
      self.table_name = "schema_migrations"

      attribute :foo
      attribute :bar
    end
  end

  let :query do
    Class.new { include API::Concerns::Orderable }.new
  end

  describe "#sort_order" do
    it "returns a formatted sort order relative to the model" do
      sort_order = query.sort_order(sort: "-foo,bar,invalid", model:, default: { id: :asc })
      expect(sort_order).to eq("#{model.table_name}.foo DESC, #{model.table_name}.bar ASC")
    end

    it "returns nil when there is no sort" do
      expect(query.sort_order(sort: " ", model:)).to be_nil
    end

    it "returns the default sort order when there is no sort" do
      default = { created_at: :asc }
      sort_order = query.sort_order(sort: nil, default:, model:)
      expect(sort_order).to eq(default)
    end
  end
end
