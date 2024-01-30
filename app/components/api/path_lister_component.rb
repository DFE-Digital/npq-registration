module Api
  class PathListerComponent < ViewComponent::Base
    def initialize(docs)
      @docs = docs
    end
  end
end
