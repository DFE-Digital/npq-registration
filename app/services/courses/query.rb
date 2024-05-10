module Courses
  class Query
    attr_reader :scope

    def initialize
      @scope = Course.all
    end

    def courses
      scope.order(name: :asc)
    end

    def course(id:)
      scope.find_by!(id:)
    end
  end
end
