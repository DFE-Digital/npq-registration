# spec/requests/api/v3/statements_request_spec.rb

require 'rails_helper'

# Open points:
# Are we able with using JBuilder for JSON generation
#
# Are we happy with doing light testing on the integration
# tests: we rely most of our testing on ServiceObject tests and
# on the controller tests (if we use them)
#
# Some of these tests are duplicated in the controller test, do we need both?
RSpec.describe "API::V3::Statements", type: :request do
  let(:statement) { create(:statement) }

  describe 'GET /index' do
    before do
      get api_v3_statements_path
    end

    xit 'returns http success'
    xit 'returns filtered statements'
    xit 'only accepts json format'
    xit 'returns 404 if statement does not exist'

    describe 'JSON format' do
      xit 'formats the statement correctly'
    end
  end
end