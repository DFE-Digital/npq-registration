module Schools
  class Query
    include Queries::ConditionFormats

    attr_reader :scope

    def initialize
      @scope = School.all
    end

    def schools
      scope.order(name: :asc)
    end

    def school(id:)
      scope.find_by!(id:)
    end
  end
end
