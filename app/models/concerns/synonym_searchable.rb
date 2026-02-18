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
        if name&.downcase&.match?(%r{\b#{key}\b}i)
          synonym_name = name.downcase.gsub(key, value)
          return scope + search_method.call(synonym_name)
        end
      end
      scope
    end
  end
end
