module Forms
  class Complete
    include ActiveModel::Model

    attr_accessor :wizard

    def self.permitted_params
      []
    end
  end
end
