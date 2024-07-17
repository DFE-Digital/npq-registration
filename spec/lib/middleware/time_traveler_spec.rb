require "rails_helper"
require "middleware/time_traveler"

RSpec.describe Middleware::TimeTraveler, type: :request do
  let(:app) { proc { [200, {}, Time.zone.now.to_s] } }
  let(:middleware) { described_class.new(app) }
  let(:request) { Rack::MockRequest.new(middleware) }
  let(:headers) { {} }

  subject do
    response = request.get("/", headers)
    Time.zone.parse(response.body)
  end

  it { is_expected.to be_within(1.minute).of(Time.zone.now) }

  context "when the HTTP_X_WITH_SERVER_DATE header is present" do
    let(:travelled_time) { Time.zone.local(2021, 8, 8, 10, 10, 0) }
    let(:headers) { { "HTTP_X_WITH_SERVER_DATE" => travelled_time.iso8601 } }

    it { is_expected.to be_within(1.minute).of(travelled_time) }

    context "when in the production environment" do
      before { allow(Rails).to receive(:env) { "production".inquiry } }

      it { is_expected.to be_within(1.minute).of(Time.zone.now) }
    end
  end
end
