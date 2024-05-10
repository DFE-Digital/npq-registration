module CourseService
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
      # Sort so items with replaced_by_value are last which will make sure the replacements
      # exist by the time they are created, meaning the loader only needs to run once to
      # build the records and create the links. Order has no affect on records.
      ::Courses::DEFINITIONS.sort_by { |h| h[:replaced_by_value] }
                            .reverse
                            .each do |hash|
                              Rails.logger.info("Loading Course with ecf_id #{hash[:ecf_id]}") unless silent

                              course = Course.find_or_initialize_by(ecf_id: hash[:ecf_id])

                              replaced_by = Course.find_by(identifier: hash[:replaced_by_identifier])

                              course.update!(
                                name: hash[:name],
                                description: hash[:description],
                                position: hash[:position],
                                display: hash[:display],
                                identifier: hash[:identifier],
                                replaced_by:,
                              )

                              unless silent
                                Rails.logger.info("Course #{course.identifier} updated:")
                                Rails.logger.info(JSON.pretty_generate(course.as_json))
                              end
                            end
    end
  end
end
