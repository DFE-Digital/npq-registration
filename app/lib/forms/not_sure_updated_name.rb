module Forms
  class NotSureUpdatedName
    include ActiveModel::Model

    attr_accessor :wizard

    def self.permitted_params
      []
    end

    def previous_step
      :updated_name
    end
  end
end
