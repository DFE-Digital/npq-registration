module Migration::Migrators
  class Cohort < Base
    def call
      migrate(ecf_cohorts) do |ecf_cohort|
        cohort = ::Cohort.find_or_initialize_by(start_year: ecf_cohort.start_year)
        cohort.update!(registration_start_date: ecf_cohort.npq_registration_start_date.presence || ecf_cohort.registration_start_date)
      end
    end

  private

    def ecf_cohorts
      @ecf_cohorts ||= Migration::Ecf::Cohort.where(start_year: 2021..)
    end
  end
end
