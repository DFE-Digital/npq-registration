require "rails_helper"

RSpec.describe PublicPagesController do
  controller do
    def index
      head :ok
    end
  end

  before { allow(Sentry).to receive(:set_user) }

  it "does not set sentry user" do
    get :index

    expect(Sentry).not_to have_received(:set_user)
  end

  it "sets caching headers" do
    get :index

    expect(response.headers).to include "Cache-Control" => "no-store"
  end
end
