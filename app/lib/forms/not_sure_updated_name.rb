module Forms
  class NotSureUpdatedName
    include ActiveModel::Model

    def self.permitted_params
      []
    end

    def previous_step
      :updated_name
    end
  end
end
