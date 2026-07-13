namespace :one_off do
  desc "Remove OAuth refresh tokens for users with TRNs"
  task remove_refresh_tokens_for_users_with_trns: :versioned_environment do
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

    tokens = OauthToken.overdue_refresh.joins(:user).where.not(user: { trn: nil })
    logger.info("Overdue OAuth refresh tokens for users with TRNs: #{tokens.count}")

    tokens.destroy_all

    logger.info("Tokens deleted.")
    logger.info(
      "Overdue OAuth refresh tokens for users with TRNs: " \
      "#{OauthToken.overdue_refresh.joins(:user).where.not(user: { trn: nil }).count}",
    )
  end
end
