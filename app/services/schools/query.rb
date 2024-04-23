module Schools
  class Query
    def schools
      School.all.order(name: :asc)
    end

    def school(id:)
      schools.find_by!(id:)
    end
  end
end
