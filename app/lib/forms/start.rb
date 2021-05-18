module Forms
  class Start
    include ActiveModel::Model

    attr_accessor :wizard

    def self.permitted_params
      []
    end
  end
end
