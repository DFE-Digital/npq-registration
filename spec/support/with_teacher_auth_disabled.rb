# frozen_string_literal: true

RSpec.shared_context "with teacher auth disabled", shared_context: :metadata do
  around do |example|
    Rails.configuration.x.teacher_auth.enabled = false
    example.run
    Rails.configuration.x.teacher_auth.enabled = true
  end
end

RSpec.configure do |config|
  config.include_context "with teacher auth disabled", :with_teacher_auth_disabled
end
