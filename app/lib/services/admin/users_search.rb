class Services::Admin::UsersSearch
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
      chain = chain.or(default_scope.where(users[:ecf_id].matches("%#{q}%")))
    end

    chain
  end

private

  def default_scope
    User.all
  end
end
