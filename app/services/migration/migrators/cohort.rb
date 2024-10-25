module Migration::Migrators
  class Cohort < Base
    class << self
      def record_count
        ecf_cohorts.count
      end

      def model
        :cohort
      end

      def ecf_cohorts
        Migration::Ecf::Cohort.where(start_year: 2021..)
      end
    end

    def call
      migrate(self.class.ecf_cohorts) do |ecf_cohort|
        cohort = ::Cohort.find_or_initialize_by(ecf_id: ecf_cohort.id)
        cohort.update!(
          start_year: ecf_cohort.start_year,
          registration_start_date: ecf_cohort.npq_registration_start_date.presence || ecf_cohort.registration_start_date,
          created_at: ecf_cohort.created_at,
          updated_at: ecf_cohort.updated_at,
        )
      end
    end
  end
end
