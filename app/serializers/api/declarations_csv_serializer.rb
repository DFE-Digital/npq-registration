# frozen_string_literal: true

require "csv"

module API
  class DeclarationsCsvSerializer
    attr_reader :declarations, :view

    ATTRIBUTES_TO_EXCLUDE = %w[type].freeze

    def initialize(declarations, view:)
      @declarations = declarations
      @view = view
    end

    def serialize
      return if declarations.empty?

      CSV.generate do |csv|
        csv << headers

        declarations_json.each do |declaration_json|
          csv << to_row(declaration_json, headers:)
        end
      end
    end

  private

    def declarations_json
      @declarations_json ||= JSON.parse(DeclarationSerializer.render(declarations, view: :v1)).map(&method(:flatten_hash))
    end

    def headers
      declarations_json.map(&:keys).flatten.uniq.excluding(ATTRIBUTES_TO_EXCLUDE)
    end

    def to_row(declaration_json, headers:)
      headers.map { |header| declaration_json[header] }
    end

    def flatten_hash(hash)
      hash.each_with_object({}) do |(key, value), result|
        if value.is_a?(Hash)
          result.merge!(flatten_hash(value))
        else
          result[key] = value
        end
      end
    end
  end
end
