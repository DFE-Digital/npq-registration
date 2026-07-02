FactoryBot.define do
  factory :admin do
    full_name { "John Doe" }
    sequence(:email) { |n| "admin#{n}@example.com" }

    trait :archived do
      archived_at { Time.current }
    end

    trait :otp_locked do
      otp_hash { nil }
      otp_expires_at { nil }
      otp_failed_attempts { Admin::MAX_OTP_FAILED_ATTEMPTS }
    end
  end

  factory :super_admin, class: "Admin" do
    full_name { "Super Doe" }
    sequence(:email) { |n| "superadmin#{n}@example.com" }
    super_admin { true }

    trait :archived do
      archived_at { Time.current }
    end
  end
end
