# frozen_string_literal: true

module API
  module Concerns
    module FilterIgnorable
      extend ActiveSupport::Concern

      def ignore?(filter:)
        filter == :ignore || (!filter.nil? && filter.blank?)
      end
    end
  end
end
