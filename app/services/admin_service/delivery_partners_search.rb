class AdminService::DeliveryPartnersSearch
  def initialize(q:)
    @q = q.to_s.strip
  end

  def call
    return DeliveryPartner.all if @q.blank?
    DeliveryPartner.name_or_ecf_id_similar_to(@q)
  end
end
