module Forms
  class Base
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks

    attr_accessor :wizard

    def self.permitted_params
      []
    end

    def previous_step
      raise NotImplementedError
    end

    def next_step
      raise NotImplementedError
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

    def answers_will_change?
      !no_answers_will_change?
    end

    def no_answers_will_change?
      wizard.store.slice(*self.class.permitted_params.map(&:to_s)) == attributes.stringify_keys
    end

    def requirements_met?
      wizard.store.present?
    end
  end
end
