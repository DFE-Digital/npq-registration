module Forms
  module QuestionTypes
    # This is a complex question type that acts as a superclass for AutoCompleteSchool and AutoCompleteNursery.
    # It is not used directly.
    #
    # The question's complexity comes from providing support for non-JS fallbacks.
    # In a JS environment the user is presented with a single input field, when a search term is entered
    # a list of possible institutions is displayed and the user can select one.
    #
    # In a no-JS environment the user is presented with a single input field, this is rendered by js.html.erb
    # initially as a fallback for non-js users. Once the search term is submitted the user is redirected back
    # to the same page with the options parameter populated using the search term and the institution_location.
    # The user is then presented with a set of radio buttons to choose from.
    # The question is rendered as a text field with a hidden field for the institution identifier.
    #
    # Forms::QuestionTypes::AutoCompleteInstitution parameters:
    #  name: The name of the field
    #  options: The list of possible institutions to display in the radio buttons, only used in no-js scenario
    #  locale_keys: The locale keys to use for the question title
    #  display_no_javascript_fallback_form: Whether to display the fallback form
    #  search_question_name: The name of the field to use for the search term in the fallback form
    #  institution_location: The location to render into hints and labels

    class AutoCompleteInstitution < Base
      def picker_type
        raise NotImplementedError
      end

      def display_no_javascript_fallback_form?
        display_no_javascript_fallback_form
      end
    end
  end
end
