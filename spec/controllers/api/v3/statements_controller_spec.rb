# frozen_string_literal: true

require 'rails_helper'

### Open points
# Do we need controller tests? Or do we rely on Integration/Request tests
# Do we stub the service layer? Or do we rely on a real database request?
RSpec.describe API::V3::StatementsController, type: :controller do

  let(:statement) { create(:statement) }
  let(:statements) { create_list(:statement, 3) }

  describe 'GET #show' do
    before do
      get :show, params: { id: statement.id }
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'returns the correct statement' do
      expect(JSON.parse(response.body)['id']).to eq(statement.id)
    end

    xit 'return not found if the statement does not exist'
    xit 'return unauthorized if the user is not authorized to access the statement'
    xit 'only accepts json format'
  end

  describe 'GET #index' do
    before do
      get :index
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'returns all statements' do
      expect(JSON.parse(response.body).size).to eq(statements.size)
    end

    xit 'only accepts json format'
    xit 'returns unauthorized if the user is not authorized to access the statements'
    xit 'returns empty list if there are no statements'
  end
end