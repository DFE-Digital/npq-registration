module Helpers
  module I18nHelper
    def t(key, **options)
      I18n.t(".#{key}", scope: [described_class.name.underscore.gsub("/", ".")], **options)
    end
  end
end
