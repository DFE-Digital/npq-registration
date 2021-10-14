class Services::QueryStore
  attr_reader :store

  def initialize(store:)
    @store = store
  end

  def england_teacher?
    store["teacher_catchment"] == "yes"
  end
end
