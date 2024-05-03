class AdminService::UsersSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    chain = default_scope

    if q.present?
      users = User.arel_table

      chain = chain.where(users[:email].matches("%#{q}%"))
      chain = chain.or(default_scope.where(users[:full_name].matches("%#{q}%")))
      chain = chain.or(default_scope.where(ecf_id: q))
      chain = chain.or(default_scope.where(applications: { ecf_id: q }))
      chain = chain.or(default_scope.where(users[:trn].matches("%#{q}%")))
      chain = chain.or(default_scope.where(applications: { school_id: find_schools.pluck(:id) }))
      chain = chain.or(default_scope.where(applications: { private_childcare_provider_id: find_private_childcare_providers.pluck(:id) }))
    end

    chain
  end

private

  def find_schools
    School.where("urn ILIKE ?", "%#{q}%")
  end

  def default_scope
    User.left_joins(:applications).order(email: :asc)
  end

  def find_private_childcare_providers
    PrivateChildcareProvider.where("provider_urn ILIKE ?", "%#{q}%")
  end
end
