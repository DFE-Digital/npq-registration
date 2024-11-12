require "rails_helper"

RSpec.describe API::QualificationsSerializer, type: :serializer do
  let(:outcome) { create(:participant_outcome, :passed) }
  let(:trn) { outcome.declaration.application.user.trn }

  subject(:response) { JSON.parse(described_class.render(trn, root: "data", participant_outcomes: [outcome])) }

  it "serializes the `trn`" do
    expect(response["data"]["trn"]).to eq(trn)
  end

  it "serializes the qualifications" do
    expect(response["data"]["qualifications"].first["award_date"]).to eq outcome.completion_date.to_fs(:db)
    expect(response["data"]["qualifications"].first["npq_type"]).to eq outcome.course.short_code
  end
end
