# frozen_string_literal: true

require "rails_helper"

RSpec.describe EligibilityLists::Update do
  subject { described_class.new(eligibility_list_type:, file:).call }

  let(:eligibility_list_type) { EligibilityList.eligibility_list_types[:pp50_school] }
  let(:file) { tempfile_with_bom("URN\n#{urn}\n") }
  let(:urn) { "100001" }

  before do
    create(:eligibility_list, identifier: "200000", eligibility_list_type:, identifier_type: "urn")
    create(:eligibility_list, identifier: "300000", eligibility_list_type:, identifier_type: "urn")
  end

  it "deletes existing records for that eligibility list type" do
    expect { subject }.to change { EligibilityList.where(eligibility_list_type:).count }.from(2).to(1)
  end

  it "creates new records from the uploaded file" do
    expect { subject }.to change {
      EligibilityList.where(eligibility_list_type:, identifier: urn, identifier_type: "urn").count
    }.from(0).to(1)
  end
end
