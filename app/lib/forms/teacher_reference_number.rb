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

    # Required since this is the first question
    # If it wasn't overridden it would check if any previous questions were answered
    # and since there aren't any it would assume the user was trying to skip questions
    # and redirect them to the start page
    # Only overridden when this is the first question, which is now when the GAI pilot is on
    # for the current user
    def requirements_met?
      return true if wizard.tra_get_an_identity_omniauth_integration_active?

      super
    end

    def next_step
      case trn_knowledge
      when "yes"
        # As the button that would lead here should be replaced in this scenario with a link to GAI this is not an
        # intended pathway, However, if JS is disabled then the request to the initial call to the form will have
        # been a html request instead of a JS request, leading to needing to properly render a page to direct the user
        # to. In case we have this fallback to take you to an interstitial page that can only go to the
        # Get an Identity service.
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
      if wizard.tra_get_an_identity_omniauth_integration_active?
        :work_setting
      else
        :start
      end
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
