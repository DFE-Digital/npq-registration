class AdminService::DeliveryPartnersSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    default_scope.contains(q).or(DeliveryPartner.where(ecf_id: q))
  end

private

  def default_scope
    DeliveryPartner.order(name: :asc)
  end
end
