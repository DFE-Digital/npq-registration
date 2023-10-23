class AutocompleteIttProviders
  def self.as_open_structs
    names.map do |name|
      OpenStruct.new(name:)
    end
  end

  def self.as_autocomplete_options
    IttProvider.find_each.map do |provider|
      [provider.legal_name, provider.legal_name, { 'data-additional-synonyms': [provider.operating_name].to_json }]
    end
  end

  def self.names
    @names ||= IttProvider.all.pluck(:legal_name)
  end
end
