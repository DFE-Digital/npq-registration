module Services
  class EarlyYearsFundingChecker
    def initialize(query_store, course_id)
      @query_store = query_store
      @course = Course.find_by(id: course_id)
    end

    def run
      @query_store.inside_catchment? &&
        @query_store.works_in_private_childcare_provider? &&
        @query_store.store["institution_identifier"].present? &&
        @course.eyl?
    end
  end
end
