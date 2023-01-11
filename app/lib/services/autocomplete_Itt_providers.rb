class Services::AutocompleteIttProviders
  def self.as_open_structs
    names.map do |name|
      OpenStruct.new(name:)
    end
  end

  def self.names
    @names ||= IttProvider.all.pluck(:legal_name)
  end
end