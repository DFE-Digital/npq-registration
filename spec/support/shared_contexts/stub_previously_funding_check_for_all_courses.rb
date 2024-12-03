RSpec.shared_context("Stub previously funding check for all courses") do # rubocop:disable RSpec/ContextWording:
  let(:trn) { raise NotImplementedError }

  before do
    user = create(:user, trn:)
    Course.all.find_each do |course|
      create(:application, :previously_funded, user:, course:)
    end
  end
end
