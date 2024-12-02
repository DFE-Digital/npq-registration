FactoryBot.define do
  factory :file_upload do
    admin { create(:admin) }
    file { nil }
  end
end
