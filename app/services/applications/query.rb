module Applications
  class Query
    def initialize(lead_provider: nil, cohort_start_years: nil, updated_since: nil, participant_ids: nil)
      @lead_provider = lead_provider
      @cohort_start_years = cohort_start_years&.split(",")
      @updated_since = updated_since
      @participant_ids = participant_ids&.split(",")
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
      scope = scope.where(cohort: { start_year: cohort_start_years }) if cohort_start_years.present?
      scope = scope.where(user: { ecf_id: participant_ids }) if participant_ids.present?
      scope = scope.where(updated_at: updated_since..) if updated_since.present?

      scope.order(created_at: :asc)
    end

    def application(id: nil, ecf_id: nil)
      return applications.find_by!(ecf_id:) if ecf_id.present?
      return applications.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

  private

    attr_reader :lead_provider, :cohort_start_years, :updated_since, :participant_ids
  end
end
