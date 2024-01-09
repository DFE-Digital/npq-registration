require "rails_helper"

RSpec.describe Migration::Result, type: :model do
  it { expect(described_class.table_name).to eq("migration_results") }
end
