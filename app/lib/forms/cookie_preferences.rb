module Forms
  class CookiePreferences
    VALID_CONSENT_OPTIONS = %w[accept reject].freeze

    include ActiveModel::Model

    attr_accessor :consent

    validates :consent, inclusion: { in: VALID_CONSENT_OPTIONS }
  end
end
