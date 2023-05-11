module Forms
  module QuestionTypes
    # See Forms::QuestionTypes::AutoCompleteInstitution for info on this class
    class AutoCompleteSchool < AutoCompleteInstitution
      def picker_type
        :school
      end
    end
  end
end
