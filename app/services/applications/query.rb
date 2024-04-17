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

    def application(id:)
      applications.find_by!(ecf_id: id)
    end

  private

    attr_reader :lead_provider
  end
end
