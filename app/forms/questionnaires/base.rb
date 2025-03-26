module Questionnaires
  class Base
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    include Questionnaires::FlowHelper

    attr_accessor :wizard

    def self.permitted_params
      []
    end

    def skip_step?
      false
    end

    def last_step?
      false
    end

    # Previous steps should lead to `closed` when registration is closed.
    def previous_step
      return :closed if Feature.registration_closed?

      raise NotImplementedError
    end

    # Subsequent steps should lead to `closed` when registration is closed.
    def next_step
      return :closed if Feature.registration_closed?

      raise NotImplementedError
    end

    def redirect_to_change_path?
      changing_answer? && next_step != :check_answers && !return_to_regular_flow?
    end

    def before_render
      reset_store! if wizard.store["submitted"]
    end

    def after_save; end

    def after_render; end

    def attributes
      self.class.permitted_params.index_with do |key|
        public_send(key)
      end
    end

    def flag_as_changing_answer
      @changing_answer = true
    end

    def changing_answer?
      @changing_answer
    end

    # Determines whether to return user from /registration/:step/change paths
    # to /registration/:step paths when data changes.
    #
    # This is used when something very core to the data being gathered changes.
    #
    # For example, if a user who said they didn't work in a school changes to
    # say that they do work in a school or the other way around then we need to
    # put them back into the regular flow to make sure they don't get sent back
    # to the check answers page before they answer any new questions that may
    # need answering.
    def return_to_regular_flow_on_change?
      false
    end

    def return_to_regular_flow?
      return_to_regular_flow_on_change? && answers_will_change?
    end

    def answers_will_change?
      !no_answers_will_change?
    end

    def no_answers_will_change?
      wizard.store.slice(*self.class.permitted_params.map(&:to_s)) == attributes.stringify_keys
    end

    def return_to_new_registration_flow?
      wizard.current_user.present? && wizard.current_step == :change_your_course_or_provider
    end

    def requirements_met?
      # Redirect to new registration flow if a user wants to change the course or provider details
      return true if return_to_new_registration_flow?

      # Ensures the user is:
      # a) logged in
      # b) has answered at least one question
      # Before allowing them to proceed into any questions.
      # Certain questions, such as start and provider_check, override this
      # as they are the first questions in the flow.
      # Some questions add additional requirements, such as the confirmation page which requires
      # a lead provider and a course to have been selected.
      wizard.store.present? &&
        query_store.current_user.present? &&
        wizard.store.keys != %w[current_user]
    end

    def reset_store!
      wizard.store.clear
    end

    def query_store
      wizard.query_store
    end

    def build_option_struct(value:, label: nil, hint: nil, link_errors: false, divider: false, revealed_question: nil)
      QuestionTypes::RadioOption.new(
        value:,
        label:,
        hint:,
        link_errors:,
        divider:,
        revealed_question:,
      )
    end
  end
end
