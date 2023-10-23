class AdminService::ApplicationsSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    chain = default_scope

    if q.present?
      chain = chain.where("users.email ilike ?", "%#{q}%")
      chain = chain.or(default_scope.where(ecf_id: q))
      chain = chain.or(default_scope.where(users: { ecf_id: q }))
    end

    chain
  end

private

  def default_scope
    Application.joins(:user).includes(:user, :course, :lead_provider).order(id: :asc)
  end
end
