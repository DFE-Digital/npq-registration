module Applications
  class Find
    def all
      Application.eager_load(:user, :school)
    end
  end
end
