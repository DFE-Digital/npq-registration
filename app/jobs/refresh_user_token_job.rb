class RefreshUserTokenJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user&.needs_token_refresh?

    token_record = user.oauth_token
    new_token = TeacherAuth::RefreshAccessToken.call(refresh_token: token_record.token)
    token_record.update!(token: new_token, token_updated_at: Time.current)
  rescue StandardError => e
    Sentry.capture_exception(e, extra: { user_id: })
  end
end
