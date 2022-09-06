module Forms
  class Base
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks

    attr_accessor :wizard

    def self.permitted_params
      []
    end

    # Previous steps should lead to `closed` when registration is closed.
    def previous_step
      return :closed if Services::Feature.registration_closed?

      raise NotImplementedError
    end

    # Subsequent steps should lead to `closed` when registration is closed.
    def next_step
      return :closed if Services::Feature.registration_closed?

      raise NotImplementedError
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

    def requirements_met?
      wizard.store.present?
    end

    def reset_store!
      wizard.store.clear
    end

    def query_store
      wizard.query_store
    end

    def build_option_struct(value:, link_errors: false, divider: false, revealed_question: nil)
      Forms::QuestionTypes::RadioOption.new(
        value:,
        link_errors:,
        divider:,
        revealed_question:,
      )
    end
  end
end
