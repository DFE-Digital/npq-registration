module Forms
  module QuestionTypes
    class Base
      attr_reader :name, :options, :locale_keys, :question_data

      def initialize(name:, options: [], style_options: {}, locale_keys: {}, **question_data)
        @name = name
        @options = options
        @style_options = style_options # Freeform optional parameters that can differ for each subclass
        @locale_keys = locale_keys
        @question_data = OpenStruct.new(question_data)
      end

      delegate_missing_to :question_data

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

      def name_locale_key
        locale_keys[:name] || name
      end

    private

      attr_reader :style_options
    end
  end
end
