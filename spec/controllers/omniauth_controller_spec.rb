require "rails_helper"

RSpec.describe OmniauthController, type: :controller do
  let(:old_user) { create(:user, :with_teacher_auth) }
  let(:user) { create(:user, :with_teacher_auth) }
  let(:feature_flag_id) { "some-feature-flag-id" }
  let(:log_session_id) { "some-log-session-id" }

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["omniauth.auth"] = create(:omniauth_auth_hash)
    allow(User).to receive(:find_or_create_from_teacher_auth).and_return(user)
    session["user_id"] = old_user.id
    session["feature_flag_id"] = feature_flag_id
    session["log_session_id"] = log_session_id
    session["some_random_var"] = "something which should be cleared"

    allow(controller).to receive(:reset_session).and_call_original
  end

  it "keeps safe session keys and removes all others" do
    post :teacher_auth
    expect(controller).to have_received(:reset_session)
    expect(session["feature_flag_id"]).to eq(feature_flag_id)
    expect(session["user_id"]).to eq(user.id)
    expect(session["log_session_id"]).to eq(log_session_id)
    expect(session["some_random_var"]).to be_nil
  end
end
