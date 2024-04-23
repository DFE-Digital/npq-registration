module Applications
  class Query
    def initialize(lead_provider: nil)
      @lead_provider = lead_provider
    end

    def applications
      scope = Application
        .includes(
          :course,
          :user,
          :school,
          :cohort,
          :private_childcare_provider,
          :itt_provider,
        )

      scope = scope.where(lead_provider:) if lead_provider.present?

      scope.order(created_at: :asc)
    end

    def application(id: nil, ecf_id: nil)
      return applications.find_by!(ecf_id:) if ecf_id.present?
      return applications.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

  private

    attr_reader :lead_provider
  end
end
