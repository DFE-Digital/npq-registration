class AdminService::DeliveryPartnersSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    return default_scope if q.blank?

    default_scope.search_with_synonyms(q, :name_equal_or_similar_to) + default_scope.where(ecf_id: q)
  end

private

  def default_scope
    DeliveryPartner.order(name: :asc)
  end
end
