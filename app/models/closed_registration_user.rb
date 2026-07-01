class ClosedRegistrationUser < ApplicationRecord
  normalizes :email, with: ->(email) { email&.strip&.downcase }
end
