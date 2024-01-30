module Api
  class DocumentationController < ApplicationController
    def index
      # many things
      @docs = DocumentationExtractor.new
    end

    def show
      # one thing
    end
  end
end
