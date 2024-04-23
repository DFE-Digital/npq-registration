module Courses
  class Query
    def courses
      Course.all.order(name: :asc)
    end

    def course(id:)
      courses.find_by!(id:)
    end
  end
end
