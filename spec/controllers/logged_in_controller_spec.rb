require "rails_helper"

RSpec.describe LoggedInController do
  controller do
    def index
      head :ok
    end
  end

  before do
    allow(Sentry).to receive(:set_user)
  end

  context "when user is not known" do
    it "does not set sentry user" do
      get :index

      expect(Sentry).not_to have_received(:set_user)
    end

    it "sets caching headers" do
      get :index

      expect(response.headers).to include "Cache-Control" => "no-store"
    end
  end

  context "when user known" do
    let!(:user) { create(:user) }

    before do
      session[:user_id] = user.id
    end

    it "sets sentry user" do
      get :index

      expect(Sentry).to have_received(:set_user).with(id: user.id)
    end

    it "sets caching headers" do
      get :index

      expect(response.headers).to include "Cache-Control" => "no-store"
    end
  end
end
