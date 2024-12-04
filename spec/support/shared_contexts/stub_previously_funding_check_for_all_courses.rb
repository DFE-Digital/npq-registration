RSpec.shared_context("Stub previously funding check for all courses") do # rubocop:disable RSpec/ContextWording:
  before do
    mock_previous_funding(previously_funded: false)
  end
end
