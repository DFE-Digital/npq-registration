module NpqSeparation
  module Admin
    class ApplicationNotesInputComponent < ViewComponent::Base
      attr_reader :form

      def initialize(form:)
        @form = form
      end

      def call
        form.govuk_text_area :notes,
                             label: { text: "Add a note about the changes to this registration", size: "m" },
                             hint: { text: "Begin your note with the date and your initials. (Notes are for internal use only.)" },
                             max_chars: 1_000
      end
    end
  end
end
