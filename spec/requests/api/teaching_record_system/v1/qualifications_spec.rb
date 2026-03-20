require "rails_helper"

RSpec.describe "Qualifications endpoint", type: :request do
  describe "GET /api/teaching-record-system/v1/qualifications/:trn" do
    let(:path) { "/api/teaching-record-system/v1/qualifications/#{trn}" }

    it_behaves_like "the qualifications endpoint"
  end
end
