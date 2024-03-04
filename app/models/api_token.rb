class APIToken < ApplicationRecord
  has_paper_trail ignore: %i[updated_at last_used_at]

  belongs_to :lead_provider

  validates :hashed_token, presence: true

  def self.create_with_random_token!(**options)
    unhashed_token, hashed_token = Devise.token_generator.generate(APIToken, :hashed_token)
    create!(hashed_token:, **options)
    unhashed_token
  end

  def self.find_by_unhashed_token(unhashed_token)
    hashed_token = Devise.token_generator.digest(APIToken, :hashed_token, unhashed_token)
    find_by(hashed_token:)
  end

  def self.create_with_known_token!(token, **options)
    hashed_token = Devise.token_generator.digest(APIToken, :hashed_token, token)
    find_or_create_by!(hashed_token:, **options)
  end
end
