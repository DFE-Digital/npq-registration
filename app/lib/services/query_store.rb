class Services::QueryStore
  attr_reader :store

  def initialize(store:)
    @store = store
  end

  def inside_catchment?
    store["teacher_catchment"] == "england" || store["teacher_catchment"] == "jersey_guernsey_isle_of_man"
  end

  def where_teach_humanized
    if store["teacher_catchment"] == "another"
      store["teacher_catchment_country"]
    else
      I18n.t(store["teacher_catchment"], scope: %i[activemodel attributes forms/teacher_catchment teacher_catchment])
    end
  end

  def teacher?
    store["teacher_status"] == "yes"
  end
end
