module LeadProviders
  class Find
    def all
      LeadProvider.all
    end

    def find_by_id(id)
      LeadProvider.find(id)
    end
  end
end
