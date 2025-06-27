RSpec.shared_examples "a model that validates participant_id currency" do
  let(:participant_id_change) { create(:participant_id_change) }
  let(:participant_id) { participant_id_change.from_participant_id }

  it { is_expected.to have_error(:participant_id, :changed, I18n.t("participant_id.changed", **participant_id_change.i18n_params)) }
end

RSpec.shared_examples "an API endpoint that checks participant_id currency" do
  let(:participant_id_change) { create(:participant_id_change) }
  let(:participant_id) { participant_id_change.from_participant_id }

  before { api_get path }

  it "returns a 410 gone status" do
    expect(response).to have_http_status(:gone)
  end

  it "returns the correct error message" do
    expect(parsed_response["errors"]).to eq([
      {
        "title" => "Participant ID has been changed",
        "detail" => I18n.t("participant_id.changed", **participant_id_change.i18n_params),
        "participant_id_changes" => [
          {
            "from_participant_id" => participant_id_change.from_participant_id,
            "to_participant_id" => participant_id_change.to_participant_id,
            "changed_at" => participant_id_change.created_at.rfc3339,
          },
        ],
      },
    ])
  end
end
