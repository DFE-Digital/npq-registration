module Users
  class Find
    def all
      User.all
    end

    def by_id(id)
      User.find(id)
    end
  end
end
