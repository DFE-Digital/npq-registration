module NpqSeparation
  class ApplicationTallyComponent < ViewComponent::Base
    attr_reader :applications, :dimension

    def initialize(applications, dimension)
      @applications = applications
      @dimension = dimension
    end

    def rows
      applications.joins(dimension).pluck(column).tally.sort
    end

  private

    def column
      "#{dimension.to_s.pluralize}.name"
    end
  end
end
