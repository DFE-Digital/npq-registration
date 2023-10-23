class AutocompleteCountries
  def self.as_open_structs
    names.map do |name|
      OpenStruct.new(name:)
    end
  end

  def self.names
    @names ||= JSON.parse(File.read(Rails.root.join("public/location-autocomplete-graph.json")))
                   .map { |_, data| data["names"]["en-GB"] }
  end
end
