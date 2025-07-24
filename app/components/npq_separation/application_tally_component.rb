module NpqSeparation
  class ApplicationTallyComponent < ViewComponent::Base
    attr_reader :applications, :dimension, :dimension_header

    # Dimension is a relation name that we group by our records eg :course or :lead_provider
    def initialize(applications, dimension, dimension_header: nil)
      @applications = applications
      @dimension = dimension
      @dimension_header = dimension_header || dimension.to_s.titleize
    end

    # Eg. `[1,2,3,3,2,4,5].tally`
    def rows
      # if params[:cohort_id].present?
      #   cohort = Cohort.find_by(id: params[:cohort_id])
      #   # we add condition ie. only one cohort
      #   applications = Application.where(cohort: @cohort)
      # else
      #   # we add condition ie. only one cohort
      #   applications = Application
      # end
      applications.joins(dimension).pluck(column).tally.sort
    end

    def total_row
      rows.sum { |_, count| count }
    end

  private

    def column
      "#{dimension.to_s.pluralize}.name"
    end

  end
end
