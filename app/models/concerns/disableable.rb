module Disableable
  extend ActiveSupport::Concern

  included do
    default_scope { where(disabled_at: nil) }

    scope :including_disabled, -> { unscope(where: :disabled_at) }
  end
end
