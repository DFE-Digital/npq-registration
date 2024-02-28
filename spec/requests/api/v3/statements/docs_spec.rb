require 'swagger_helper'

# Open points:
# Do we have a separate Spec for all endpoints?
# Do we have a separate file with the docs? statements/index_docs_spec.rb
# Do we embed the docs on each spec? statements/index_spec.rb
RSpec.describe 'Statements API', type: :request do
  path '/api/v3/statements/{id}' do
    get 'Retrieves a statement' do
      tags 'Statements'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string

      response '200', 'statement found' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            # other statement properties
          },
          required: [ 'id' ]

        let(:id) { Statement.create.id }
        run_test!
      end

      response '404', 'statement not found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end