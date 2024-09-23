# frozen_string_literal: true

FactoryBot.define do
  factory :participant_id_change do
    user
    from_participant_id { SecureRandom.uuid }
    to_participant_id { user.ecf_id }
  end
end
