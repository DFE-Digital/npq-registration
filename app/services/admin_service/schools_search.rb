class AdminService::SchoolsSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    chain = default_scope

    if q.present?
      chain = chain.where(urn: q)
      chain = chain.or(default_scope.where("name ILIKE ?", "%#{q}%"))
    end

    chain
  end

private

  def default_scope
    School
  end
end
