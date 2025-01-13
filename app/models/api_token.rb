class APIToken < ApplicationRecord
  belongs_to :lead_provider, optional: true

  enum scope: {
    lead_provider: "lead_provider",
    teacher_record_service: "teacher_record_service",
  }

  validates :hashed_token, presence: true
  validates :scope, presence: true
  validates :lead_provider, presence: true, if: -> { scope == "lead_provider" }

  def self.create_with_random_token!(**options)
    unhashed_token, hashed_token = Devise.token_generator.generate(APIToken, :hashed_token)
    create!(hashed_token:, **options)
    unhashed_token
  end

  def self.find_by_unhashed_token(unhashed_token, scope:)
    hashed_token = Devise.token_generator.digest(APIToken, :hashed_token, unhashed_token)
    find_by(hashed_token:, scope: scope)
  end

  # only used in specs and seeds
  def self.create_with_known_token!(token, scope: scopes[:lead_provider], **options)
    hashed_token = Devise.token_generator.digest(APIToken, :hashed_token, token)
    find_or_create_by!(hashed_token:, scope:, **options)
  end
end
