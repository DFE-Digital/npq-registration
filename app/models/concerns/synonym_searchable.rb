module SynonymSearchable
  extend ActiveSupport::Concern

  NAME_SYNONYMS = {
    "saint" => "st",
    "st" => "saint",
  }.freeze

  included do
    def self.search_with_synonyms(name, search_method_name)
      search_method = method(search_method_name)
      scope = search_method.call(name)
      NAME_SYNONYMS.find do |key, value|
        next unless name&.downcase&.match?(%r{\b#{key}\b}i)

        synonym_name = name.downcase.gsub(key, value)
        union = Arel::Nodes::Union.new(scope.arel, search_method.call(synonym_name).arel)
        return from(Arel::Nodes::TableAlias.new(union, table_name))
      end
      scope
    end
  end
end
