module NpqSeparation
  module Admin
    class ApplicationNotesInputComponent < BaseComponent
      attr_reader :form

      def initialize(form:)
        @form = form
      end

      def call
        form.govuk_text_area :notes,
                             label: { text: label_text, size: "m" },
                             hint: { text: "Begin your note with the date and your initials. (Notes are for internal use only.)" },
                             max_chars: 1_000
      end

    private

      def label_text
        if form.object.notes.present?
          "Edit the note about the changes to this registration"
        else
          "Add a note about the changes to this registration"
        end
      end
    end
  end
end
