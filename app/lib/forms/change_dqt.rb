module Forms
  class ChangeDqt
    include ActiveModel::Model

    attr_accessor :wizard

    def self.permitted_params
      []
    end

    def previous_step
      :not_updated_name
    end

    def next_step
      :not_updated_name
    end
  end
end
