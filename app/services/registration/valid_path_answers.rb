module Registration
  class ValidPathAnswers
    class << self
      def state_store(wizard)
        new(wizard).state_store
      end
    end

    def initialize(wizard)
      @wizard = wizard
    end

    def state_store
      hydrated_state_store_from_valid_answers
    end

  private

    def hydrated_state_store_from_valid_answers
      Registration::Wizard
        .new(state_store: build_state_store_from_valid_answers)
        .state_store
    end

    def build_state_store_from_valid_answers
      Registration::StateStore.new(
        repository: build_repository_from_valid_answers,
        current_user: @wizard.state_store.current_user,
      )
    end

    def build_repository_from_valid_answers
      DfE::Wizard::Repository::InMemory.new.tap do |repo|
        repo.write(valid_answers_from_existing_wizard)
      end
    end

    def valid_answers_from_existing_wizard
      @wizard.data[:steps].values.reduce(&:merge).symbolize_keys
    end
  end
end
