module SessionWizardSteps
  class Base
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks

    attr_accessor :wizard

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

    def reset_store!
      wizard.store.clear
    end

    def query_store
      wizard.query_store
    end
  end
end
