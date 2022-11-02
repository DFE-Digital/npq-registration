module Forms
  class TeacherReferenceNumber < Base
    VALID_TRN_KNOWLEDGE_OPTIONS = %w[yes no-dont-have].freeze

    attr_accessor :trn_knowledge

    validates :trn_knowledge, presence: true, inclusion: { in: VALID_TRN_KNOWLEDGE_OPTIONS }

    def self.permitted_params
      %i[
        trn_knowledge
      ]
    end

    def next_step
      case trn_knowledge
      when "yes"
        # This should never happen, as the button that would lead here should be replaced
        # in this scenario with a link to GAI. However, just in case we have this fallback to take
        # you to an interstitial page that can only go to GAI.
        # This can happen if JS is disabled.
        if wizard.tra_get_an_identity_omniauth_integration_active?
          :get_an_identity
        else
          :contact_details
        end
      when "no-dont-have"
        :dont_have_teacher_reference_number
      end
    end

    def previous_step
      :work_setting
    end

    def title
      if assumed_to_have_trn?
        "You need your teacher reference number to register for an NPQ"
      else
        "You need a teacher reference number to register for an NPQ"
      end
    end

    def options
      [
        option("yes", "Yes", link_errors: true),
        option("no-dont-have", "No, I need help getting one"),
      ]
    end

    def assumed_to_have_trn?
      wizard.query_store.inside_catchment? && wizard.query_store.works_in_school?
    end

  private

    def option(value, text, description = nil, link_errors: false)
      OpenStruct.new(value:, text:, description:, link_errors:)
    end
  end
end
