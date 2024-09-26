# frozen_string_literal: true

module Ecf
  module Base
    def call
      return if Feature.ecf_api_disabled?

      super
    end
  end
end
