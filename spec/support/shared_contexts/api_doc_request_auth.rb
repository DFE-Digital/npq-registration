RSpec.shared_context("with authorization for api doc request") do
  let(:lead_provider) { create(:lead_provider) }
  let(:token) { APIToken.create_with_random_token!(lead_provider:) }
  let(:Authorization) { "Bearer #{token}" }
end
