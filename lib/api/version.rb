class API::Version
  class << self
    def exists?(version)
      version.to_sym.in?(all)
    end

    def all
      %i[v3]
    end
  end
end
