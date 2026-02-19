class AdminService::DeliveryPartnersSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    return default_scope if q.blank?

    search_by_id = default_scope.where(ecf_id: q)

    return search_by_id if search_by_id.any?

    default_scope.search_with_synonyms(q) do |name|
      default_scope.name_equal_or_similar_to(name)
    end
  end

private

  def default_scope
    DeliveryPartner.order(name: :asc)
  end
end
