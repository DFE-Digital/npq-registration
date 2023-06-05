module Forms
  module QuestionTypes
    class Base < ViewComponent::Base
      include ActiveModel::Attributes
      include ActiveModel::AttributeAssignment

      self.default_form_builder = GOVUKDesignSystemFormBuilder::FormBuilder

      renders_one :after_question

      attribute :name
      attribute :header
      attribute :options, default: -> { {} } # TODO: options should be moved to appropriate subclass!
      attribute :form
      attribute :style_options, default: -> { {} }
      attribute :locale_name

      def initialize(**attrs)
        super
        assign_attributes(**attrs)
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

      def style_options
        default_styles.deep_merge(super)
      end

      def default_styles
        {}
      end

      def name_locale_key
        locale_name || name
      end

      def question_text
        I18n.t("helpers.#{title_locale_type}.registration_wizard.#{name_locale_key}")
      end
    end
  end
end
