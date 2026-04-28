module Registration
  class ClearApplicationData
    def initialize(repository:, step:)
      @repository = repository
      @step = step
    end

    def execute
      @repository.clear

      { success: true }
    end
  end
end
