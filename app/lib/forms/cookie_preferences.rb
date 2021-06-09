module Forms
  class CookiePreferences
    VALID_CONSENT_OPTIONS = %w[accept reject].freeze

    include ActiveModel::Model

    attr_accessor :consent, :return_path

    validates :consent, inclusion: { in: VALID_CONSENT_OPTIONS }
    validates :return_path, format: { with: /\A\// }
  end
end
