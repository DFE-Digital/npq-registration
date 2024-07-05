require "i18n/backend/chain"
require "i18n/backend/npq"

I18n.backend = I18n::Backend::Chain.new(
  I18n::Backend::NPQ.new,
  I18n.backend,
)
