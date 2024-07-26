# frozen_string_literal: true

module Ecf
  class Base
    def call
      return if Rails.application.config.npq_separation[:ecf_api_disabled]

      super
    end
  end
end
