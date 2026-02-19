module SynonymSearchable
  extend ActiveSupport::Concern

  NAME_SYNONYMS = {
    "saint" => "st",
    "st" => "saint",
  }.freeze

  included do
    def self.search_with_synonyms(name)
      scope = yield(name)

      synonym_scopes = NAME_SYNONYMS.map { |key, value|
        next unless name&.downcase&.match?(%r{\b#{key}\b}i)

        name_synonym = name.downcase.gsub(key, value)
        yield(name_synonym)
      }.compact

      union = synonym_scopes.reduce(scope.arel) do |combined_scope, synonym_scope|
        Arel::Nodes::Union.new(combined_scope, synonym_scope.arel)
      end

      from(Arel::Nodes::TableAlias.new(union, table_name))
    end
  end
end
