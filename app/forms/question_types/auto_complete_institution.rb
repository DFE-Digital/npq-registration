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
  # QuestionTypes::AutoCompleteInstitution parameters:
  #  name: The name of the field
  #
  #  options: The list of possible institutions to display in the radio buttons, only used in no-js scenario
  #
  #  style_options: Freeform optional parameters that can differ for each subclass
  #
  #  locale_name: The locale key to use for the question name instead of name
  #
  #  data_attributes: The hash to pass into the data-attributes of the input field along with into locale strings
  #
  #  picker: The type of institution to search for, either :school, :nursery, or :"private-childcare-provider".
  #          Controls which JS searcher to load
  #
  #  display_no_javascript_fallback_form: Whether to display the fallback form
  #
  #  search_question: The question used to display the search term input field in the fallback form

  class AutoCompleteInstitution < Base
    attr_reader :data_attributes,
                :picker,
                :search_question

    def initialize(
      *args,
      picker:,
      display_no_javascript_fallback_form:,
      search_question:,
      data_attributes: {},
      **opts
    )
      @data_attributes = data_attributes
      @picker = picker
      @display_no_javascript_fallback_form = display_no_javascript_fallback_form
      @search_question = search_question

      super(*args, **opts)
    end

    def display_no_javascript_fallback_form?
      @display_no_javascript_fallback_form
    end
  end
end
