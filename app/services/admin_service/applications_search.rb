class AdminService::ApplicationsSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    chain = default_scope

    if q.present?
      chain = chain.where("users.email ilike ?", "%#{q}%")
      chain = chain.or(default_scope.where("users.full_name ilike ?", "%#{q}%"))
      chain = chain.or(default_scope.where("applications.employer_name ilike ? OR schools.name ilike ?", "%#{q}%", "%#{q}%"))
      chain = chain.or(default_scope.where(ecf_id: q))
      chain = chain.or(default_scope.where(users: { ecf_id: q }))
    end

    chain
  end

private

  def default_scope
    Application.left_joins(:school).joins(:user).includes(:course, :lead_provider, :school, :user).order(id: :asc)
  end
end
