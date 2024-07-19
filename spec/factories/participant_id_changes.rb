# frozen_string_literal: true

FactoryBot.define do
  factory :participant_id_change do
    user
    association :from_participant, factory: :user
    association :to_participant, factory: :user
  end
end
