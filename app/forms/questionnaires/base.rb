module Questionnaires
  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

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
      # basic check to determine if user has completed a registration and is attempting to go directly to a step in the journey
      query_store.has_answers?
    end

    def reset_store!
      wizard.store.clear
    end

    def query_store
      wizard.query_store
    end

    def build_option_struct(value:, label: nil, hint: nil, link_errors: false, divider: false, revealed_question: nil, nested_options: nil)
      QuestionTypes::RadioOption.new(
        value:,
        label:,
        hint:,
        link_errors:,
        divider:,
        revealed_question:,
        nested_options:,
      )
    end

  private

    def show_eligibility_step
      if changing_answer?
        :check_answers
      elsif query_store.course.ehco?
        :npqh_status
      elsif query_store.course.npqlpm?
        :maths_eligibility_teaching_for_mastery
      elsif query_store.course.npqs?
        :senco_in_role
      elsif funding_eligibility_calculator.funded? || funding_eligibility_calculator.subject_to_review?
        :possible_funding
      else
        :ineligible_for_funding
      end
    end

    def check_answers_step
      if wizard.current_user
        :check_answers_and_submit
      else
        :check_answers
      end
    end

    def eligible_for_funding?
      funding_eligibility_calculator.funded?
    end

    def user_previously_funded?
      funding_eligibility_calculator.funding_eligiblity_status_code == :previously_funded
    end

    def funding_eligibility_calculator
      @funding_eligibility_calculator ||= FundingEligibility.new_from_query_store(
        course: query_store.course,
        institution: query_store.institution,
        approved_itt_provider: query_store.approved_itt_provider?,
        inside_catchment: query_store.inside_catchment?,
        user_ecf_id: query_store.user_ecf_id,
        query_store:,
      )
    end
  end
end
