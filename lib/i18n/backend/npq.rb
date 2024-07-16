module I18n
  module Backend
    class NPQ < Simple
      def interpolate(locale, string, values = {})
        if values.key?(:attribute)
          # Ensure that the attribute is exposed as a parameterized string
          # for active model error messages.
          values[:parameterized_attribute] = values[:attribute].to_s.parameterize(separator: "_")
        end

        super(locale, string, values)
      end
    end
  end
end
