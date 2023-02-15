module Forms
  module QuestionTypes
    class Base
      attr_reader :name, :options

      def initialize(name:, options: [], style_options: {})
        @name = name
        @options = options
        @style_options = style_options # Freeform optional parameters that can differ for each subclass
      end

      # For determining which partial to use
      def type
        self.class.name.demodulize.underscore
      end

      # Most questions will have their question locale string in the format `helpers.label.registration_wizard.#{question_name}`.
      # ome however, radio button groups specifically, store them under legend instead of label,
      # this method allows you to override where it looks for specific question types.
      # This is only used for the title population in _question_page.html.erb.
      def title_locale_type
        :label
      end
    end
  end
end
