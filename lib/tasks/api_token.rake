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

  namespace :lead_provider do
    desc "Generate a new API token for the Lead Providers API"
    task :generate_token, %i[lead_provider_id] => :environment do |_t, args|
      logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

      lead_provider = LeadProvider.find_by(id: args.lead_provider_id)
      raise("Unknown lead_provider_id") unless lead_provider

      scope = APIToken.scopes[:lead_provider]
      unhashed_token = APIToken.create_with_random_token!(scope:, lead_provider:)

      logger.info "API Token created: #{unhashed_token}"
      logger.info "** Important: API Tokens should only be transferred via Galaxkey **"
    end
  end
end
