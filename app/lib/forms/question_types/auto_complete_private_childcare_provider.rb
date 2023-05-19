module Forms
  module QuestionTypes
    # See Forms::QuestionTypes::AutoCompleteInstitution for info on this class
    class AutoCompletePrivateChildcareProvider < AutoCompleteInstitution
      def picker_type
        :"private-childcare-provider"
      end

      def locale_params
        {}
      end
    end
  end
end
