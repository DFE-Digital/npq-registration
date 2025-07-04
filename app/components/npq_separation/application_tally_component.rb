module NpqSeparation
  class ApplicationTallyComponent < ViewComponent::Base
    attr_reader :applications, :dimension, :dimension_header

    def initialize(applications, dimension, dimension_header: nil)
      @applications = applications
      @dimension = dimension
      @dimension_header = dimension_header || dimension.to_s.titleize
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
