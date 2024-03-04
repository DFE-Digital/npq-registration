require "rails_helper"

RSpec.describe API::V3::StatementsSerializer, type: :serializer do
  let(:subject) { described_class }
  let(:cohort) { create(:cohort) }
  let(:statements) { create_list(:statement, 3, cohort:) }

  it "serializes a collection of statements" do
    response = subject.render_as_hash(statements:)

    expect(response[:statements].size).to eq(3)
    expect(response[:statements].first[:id]).to eq(statements.first.id)
    expect(response[:statements].last[:id]).to eq(statements.last.id)
  end
end
