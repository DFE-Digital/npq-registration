RSpec.shared_context("when errors are rendered") do
  before do
    method = Rails.application.method(:env_config)
    allow(Rails.application).to receive(:env_config).with(no_args) do
      method.call.merge(
        "action_dispatch.show_exceptions" => :all,
        "action_dispatch.show_detailed_exceptions" => false,
        "consider_all_requests_local" => false,
      )
    end
  end
end
