class APIToken < ApplicationRecord
  belongs_to :lead_provider

  validates :hashed_token, presence: true

  def self.create_with_random_token!(**options)
    unhashed_token, hashed_token = Devise.token_generator.generate(APIToken, :hashed_token)
    create!(hashed_token:, **options)
    unhashed_token
  end

  def self.find_by_unhashed_token(unhashed_token)
    hashed_token = token = nil

    # cache_key = "api_token:#{unhashed_token}"

    # token = Rails.cache.read(cache_key)

    # if token.nil?

    Rack::MiniProfiler.step("Generating token digest") do
      hashed_token = Devise.token_generator.digest(APIToken, :hashed_token, unhashed_token)
    end

    Rack::MiniProfiler.step("API token authentication") do
      token = find_by(hashed_token:)
    end

    # Rails.cache.write(cache_key, token, expires_in: 10.minutes)
    # end

    token
  end

  def self.create_with_known_token!(token, **options)
    hashed_token = Devise.token_generator.digest(APIToken, :hashed_token, token)
    find_or_create_by!(hashed_token:, **options)
  end
end
