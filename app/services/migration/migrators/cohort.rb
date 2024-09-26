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
      migrate(self.class.ecf_cohorts) do |ecf_cohorts|
        ecf_cohorts.each do |ecf_cohort|
          cohort = ::Cohort.find_or_initialize_by(ecf_id: ecf_cohort.id)
          cohort.update!(
            start_year: ecf_cohort.start_year,
            registration_start_date: ecf_cohort.npq_registration_start_date.presence || ecf_cohort.registration_start_date,
          )

          increment_processed_count
        rescue ActiveRecord::ActiveRecordError => e
          increment_failure_count(ecf_cohort, e)
        end
      end
    end
  end
end
