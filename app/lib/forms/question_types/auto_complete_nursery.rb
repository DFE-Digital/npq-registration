module Forms
  module QuestionTypes
    # See Forms::QuestionTypes::AutoCompleteInstitution for info on this class
    class AutoCompleteNursery < AutoCompleteInstitution
      def picker_type
        :nursery
      end

      def locale_params
        { institution_location: institution_location }
      end
    end
  end
end
