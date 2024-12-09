RSpec.shared_context("Stub previously funding check for all courses") do # rubocop:disable RSpec/ContextWording:
  let(:trn) { raise NotImplementedError }

  before do
    user = create(:user, trn:, email: "user@example.com")
    Course.all.find_each do |course|
      create(:application, :accepted, :eligible_for_funding, user:, course:)
    end
  end
end
