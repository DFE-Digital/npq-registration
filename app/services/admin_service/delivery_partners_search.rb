class AdminService::DeliveryPartnersSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    default_scope.where("name ILIKE ?", "%#{q}%")
  end

private

  def default_scope
    DeliveryPartner.order(name: :asc)
  end
end
