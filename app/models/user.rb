class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:tra_openid_connect]

  has_many :applications, dependent: :destroy

  validates :email, uniqueness: true

  # TODO: What do we do if someone has already registered their email but not via TRA?
  # Should it hook up to the existing record or deprecate the old one?
  def self.from_provider_data(provider_data)
    user = find_by(email: provider_data.info.email, provider: nil, uid: nil)
    user ||= find_or_initialize_by(provider: provider_data.provider, uid: provider_data.uid)

    user.assign_attributes(
      provider: provider_data.provider,
      uid: provider_data.uid,
      email: provider_data.info.email,
      full_name: provider_data.info.name,
      raw_tra_provider_data: provider_data,
    )

    user.tap(&:save)
  end

  def null_user?
    false
  end
end
