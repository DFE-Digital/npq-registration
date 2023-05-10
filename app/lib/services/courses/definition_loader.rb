module Services
  module Courses
    class DefinitionLoader
      class << self
        def call(silent: false)
          new(silent:).call
        end
      end

      attr_reader :silent

      def initialize(silent:)
        @silent = silent
      end

      def call
        ::Courses::DEFINITIONS.each do |hash|
          Rails.logger.info("Loading Course with ecf_id #{hash[:ecf_id]}") unless silent

          course = Course.find_or_initialize_by(ecf_id: hash[:ecf_id])

          course.update!(
            name: hash[:name],
            description: hash[:description],
            position: hash[:position],
            display: hash[:display],
            identifier: hash[:identifier],
          )

          unless silent
            Rails.logger.info("Course #{course.identifier} updated:")
            Rails.logger.info(JSON.pretty_generate(course.as_json))
          end
        end
      end
    end
  end
end
