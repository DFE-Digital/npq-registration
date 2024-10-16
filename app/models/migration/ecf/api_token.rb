# frozen_string_literal: true

require "abstract_interface"

module Migration::Ecf
  class APIToken < BaseRecord
    has_paper_trail ignore: %i[updated_at last_used_at]
    # This is meant to be an abstract class
    # Since it is a base class for a STI, we can't actually make it abstract (not backed by a table)
    include AbstractInterface
    implement_instance_method :owner

    def self.create_with_random_token!(**options)
      unhashed_token, hashed_token = Devise.token_generator.generate(APIToken, :hashed_token)
      create!(hashed_token:, **options)
      unhashed_token
    end

    def self.find_by_unhashed_token(unhashed_token)
      hashed_token = Devise.token_generator.digest(APIToken, :hashed_token, unhashed_token)
      find_by(hashed_token:)
    end
  end
end
