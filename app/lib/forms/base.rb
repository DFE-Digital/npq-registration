module Forms
  class Base
    include ActiveModel::Model

    attr_accessor :wizard

    def self.permitted_params
      []
    end

    def previous_step
      raise NotImplementedError
    end

    def next_step
      raise NotImplementedError
    end

    def after_save; end

    def attributes
      self.class.permitted_params.index_with do |key|
        public_send(key)
      end
    end
  end
end
