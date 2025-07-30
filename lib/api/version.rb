class API::Version
  class << self
    def exists?(version)
      version.to_sym.in?(all)
    end

    def all
      Rails.configuration.x.disable_legacy_api ? %i[v3] : %i[v1 v2 v3]
    end
  end
end
