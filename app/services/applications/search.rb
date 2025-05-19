module Applications
  class Search
    attr_reader :query

    class << self
      def search(query)
        new(query).search
      end
    end

    def initialize(query)
      @query = query
    end

    def search
      return Application.all if query.blank?

      scope.where(ecf_id: query)
        .or(scope.where(declarations: { ecf_id: query }))
        .or(scope.where("users.full_name ilike ?", "%#{query}%"))
        .distinct(:ecf_id)
    end

  private

    def scope
      Application.left_joins(:user, :declarations).includes(:user, :declarations)
    end
  end
end
