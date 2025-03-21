namespace :api_token do
  namespace :teacher_record_service do
    desc "Generate a new API token for the Teacher Record Service"
    task generate_token: :environment do
      scope = APIToken.scopes[:teacher_record_service]
      logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)
      token = APIToken.create_with_random_token!(scope:)
      logger.info "API Token created: #{token}"
    end
  end
end
